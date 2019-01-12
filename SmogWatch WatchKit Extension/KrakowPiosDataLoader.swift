//
//  KrakowPiosDataLoader.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 23.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import Foundation

private let DataURL = "http://monitoring.krakow.pios.gov.pl/dane-pomiarowe/pobierz"

class KrakowPiosDataLoader {
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

    struct DataSeries: Decodable {
        enum CodingKeys: String, CodingKey {
            case points = "data"
        }

        let points: [DataPoint]
    }

    struct ResponseData: Decodable {
        let series: [DataSeries]
    }

    struct Response: Decodable {
        let data: ResponseData
    }

    let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = Locale(identifier: "en_US_POSIX")
        d.dateFormat = "dd.MM.yyyy"
        d.timeZone = TimeZone(identifier: "Europe/Warsaw")!
        return d
    }()

    let dataStore = DataStore()

    func queryString() -> String {
        let query: [String:Any] = [
            "measType": "Auto",
            "viewType": "Parameter",
            "dateRange": "Day",
            "date": dateFormatter.string(from: Date()),
            "viewTypeEntityId": "pm10",
            "channels": [148]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: query, options: [])
        let json = String(data: jsonData, encoding: .utf8)!

        return "query=\(json)"
    }

    func fetchData(_ completion: @escaping (Bool) -> ()) {
        var request = URLRequest(url: URL(string: DataURL)!)
        request.httpBody = queryString().data(using: .utf8)!
        request.httpMethod = "POST"

        Logger.log("KrakowPiosDataLoader: sending request to \(DataURL) with \(queryString()) ...")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            var success = false

            Logger.log("KrakowPiosDataLoader: response received: " +
                  (data != nil ? "\(data!.count) bytes" : "(nil)") + " " +
                  (response != nil ? "\(response!)" : "(nil)") + " " +
                  (error != nil ? "\(error!)" : "(no error)"))

            if let data = data {
                if let response = try? JSONDecoder().decode(Response.self, from: data) {
                    if let series = response.data.series.first {
                        if let point = series.points.last {
                            self.dataStore.currentLevel = point.value
                            self.dataStore.lastMeasurementDate = point.date

                            Logger.log("KrakowPiosDataLoader: saving data: %(point.value) at \(point.date)")

                            success = true
                        }
                    }
                }
            }

            if !success {
                Logger.log("KrakowPiosDataLoader: no data found")
            }

            completion(success)
        }

        task.resume()
    }
}
