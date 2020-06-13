//
//  KrakowPiosDataLoader.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 23.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import Foundation
import WatchKit

private let apiBase = "http://monitoring.krakow.pios.gov.pl"
private let dataURL = apiBase + "/dane-pomiarowe/pobierz"
private let configURL = apiBase + "/dane-pomiarowe/wczytaj-konfiguracje"

private let knownParameterNames = [
    "so2": ["SO2", "SO2", "SO"],
    "no2": ["NO2", "NO2", "NO"],
    "nox": ["NOx", "NOx", "NO"],
    "no":  ["NO", "NO", "NO"],
    "o3":  ["Ozone", "O3", "O3"],
    "co":  ["Carbon Monoxide", "CO", "CO"],
    "bzn":  ["Benzene", "Bzn", "Bzn"],
    "pm10":  ["PM10", "PM10", "PM"],
    "pm2.5":  ["PM2.5", "PM25", "PM"],
]

private struct ValuesResponse: Decodable {
    let data: ResponseData

    struct ResponseData: Decodable {
        let series: [DataSeries]

        struct DataSeries: Decodable {
            enum CodingKeys: String, CodingKey {
                case points = "data"
            }

            let points: [DataPoint]

            struct DataPoint: Decodable {
                let date: Date
                let value: Double

                struct InvalidValueError: Error {}

                init(from decoder: Decoder) throws {
                    var container = try decoder.unkeyedContainer()

                    if let timestamp = try Int(container.decode(String.self)) {
                        self.date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                    } else {
                        throw InvalidValueError()
                    }

                    if let value = try Double(container.decode(String.self)) {
                        self.value = value
                    } else {
                        throw InvalidValueError()
                    }
                }
            }
        }
    }
}

private struct ConfigResponse: Decodable {
    let config: Config

    struct Config: Decodable {
        let stations: [Station]
        let channels: [Channel]

        struct Station: Decodable {
            let id: Int
            let name: String
        }

        struct Channel: Decodable {
            let stationId: Int
            let channelId: Int
            let paramId: String
        }
    }
}

class KrakowPiosDataLoader {
    let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = Locale(identifier: "en_US_POSIX")
        d.dateFormat = "dd.MM.yyyy"
        d.timeZone = TimeZone(identifier: "Europe/Warsaw")!
        return d
    }()

    let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = 10.0

        return URLSession(configuration: config)
    }()

    let dataStore = DataStore()

    func queryString(channelId: Int) -> String {
        // data is usually around one hour behind, so at midnight we need to ask for the previous day
        let oneHourAgo = Calendar(identifier: .gregorian).date(byAdding: .hour, value: -1, to: Date())!

        let query: [String:Any] = [
            "measType": "Auto",
            "viewType": "Parameter",
            "dateRange": "Day",
            "date": dateFormatter.string(from: oneHourAgo),
            "viewTypeEntityId": "pm10",
            "channels": [channelId]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: query, options: [])
        let json = String(data: jsonData, encoding: .utf8)!

        return "query=\(json)"
    }

    func fetchData(_ completion: @escaping (Bool) -> ()) {
        guard let channelId = dataStore.selectedChannelId else {
            NSLog("KrakowPiosDataLoader: no channel selected")
            completion(false)
            return
        }

        let query = queryString(channelId: channelId)
        var request = URLRequest(url: URL(string: dataURL)!)
        request.httpBody = query.data(using: .utf8)!
        request.httpMethod = "POST"

        NSLog("KrakowPiosDataLoader: sending request [state: %@] to %@ with %@ ...",
              WKExtension.shared().applicationState.description, dataURL, query)

        let task = session.dataTask(with: request) { (data, response, error) in
            var success = false

            NSLog("KrakowPiosDataLoader: response received: %@ %@ %@",
                  data != nil ? "\(data!.count) bytes" : "(nil)",
                  response != nil ? "\(response!)" : "(nil)",
                  error != nil ? "\(error!)" : "(no error)")

            if let data = data {
                if let response = try? JSONDecoder().decode(ValuesResponse.self, from: data) {
                    if let series = response.data.series.first {
                        if let lastPoint = series.points.last {
                            self.dataStore.addPoints(
                                series.points.map({ DataPoint(date: $0.date, value: $0.value )})
                            )
                            self.dataStore.lastUpdateDate = Date()

                            NSLog("KrakowPiosDataLoader: saving data: %.0f at %@", lastPoint.value, "\(lastPoint.date)")

                            success = true
                        }
                    }
                }
            }

            if !success {
                NSLog("KrakowPiosDataLoader: no data found")
            }

            completion(success)
        }

        task.resume()
    }

    func fetchConfig(_ completion: @escaping (Bool) -> ()) {
        var request = URLRequest(url: URL(string: configURL)!)
        request.httpMethod = "POST"
        request.httpBody = "measType=Auto".data(using: .utf8)

        NSLog("KrakowPiosDataLoader: sending request to %@...", configURL)

        let task = session.dataTask(with: request) { (data, response, error) in
            var success = false

            NSLog("KrakowPiosDataLoader: response received: %@ %@ %@",
                  data != nil ? "\(data!.count) bytes" : "(nil)",
                  response != nil ? "\(response!)" : "(nil)",
                  error != nil ? "\(error!)" : "(no error)")

            if let data = data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                if let response = try? decoder.decode(ConfigResponse.self, from: data) {
                    let stations = self.parseConfigData(response.config)

                    do {
                        try self.dataStore.saveStations(stations)
                        self.dataStore.lastConfigUpdateDate = Date()

                        NSLog("KrakowPiosDataLoader: saved %d stations", stations.count)

                        success = true
                    } catch let error {
                        NSLog("DataStore: error saving stations: %@", "\(error)")
                    }
                }
            }

            if !success {
                NSLog("KrakowPiosDataLoader: no config data found")
            }

            completion(success)
        }

        task.resume()
    }

    private func parseConfigData(_ config: ConfigResponse.Config) -> [DataStation] {
        var channelMap: [Int: [DataChannel]] = [:]

        for channel in config.channels {
            var list = channelMap[channel.stationId] ?? []

            guard let paramNames = knownParameterNames[channel.paramId] else { continue }

            list.append(
                DataChannel(
                    id: channel.channelId,
                    name: paramNames[0],
                    shortName: paramNames[1],
                    veryShortName: paramNames[2]
                )
            )

            channelMap[channel.stationId] = list
        }

        return config.stations.compactMap { s in
            guard let channels = channelMap[s.id], channels.count > 0 else { return nil }

            return DataStation(id: s.id, name: s.name, channels: channels)
        }
    }
}
