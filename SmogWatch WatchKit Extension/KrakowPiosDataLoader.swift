//
//  KrakowPiosDataLoader.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 23.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import Foundation
import WatchKit

private let dataURL = "http://monitoring.krakow.pios.gov.pl/dane-pomiarowe/pobierz"

private struct Response: Decodable {
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

    func queryString(channelId: Int, date: Date? = nil) -> String {
        // data is usually around one hour behind, so at midnight we need to ask for the previous day
        let oneHourAgo = Calendar(identifier: .gregorian).date(byAdding: .hour, value: -1, to: Date())!

        let query: [String:Any] = [
            "measType": "Auto",
            "viewType": "Parameter",
            "dateRange": "Day",
            "date": dateFormatter.string(from: date ?? oneHourAgo),
            "viewTypeEntityId": "pm10",
            "channels": [channelId]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: query, options: [])
        let json = String(data: jsonData, encoding: .utf8)!

        return "query=\(json)"
    }

    func fetchData(date: Date? = nil, _ completion: @escaping (Bool) -> ()) {
        let channelId = dataStore.selectedChannelId ?? 148

        let query = queryString(channelId: channelId, date: date)
        var request = URLRequest(url: URL(string: dataURL)!)
        request.httpBody = query.data(using: .utf8)!
        request.httpMethod = "POST"

        NSLog("KrakowPiosDataLoader: sending request [state: %@] to %@ with %@ ...",
              WKExtension.shared().applicationState.description, dataURL, query)
        logStore.log(message: "sending_request")

        let task = session.dataTask(with: request) { (data, response, error) in
            var success = false

            NSLog("KrakowPiosDataLoader: response received: %@ %@ %@",
                  data != nil ? "\(data!.count) bytes" : "(nil)",
                  response != nil ? "\(response!)" : "(nil)",
                  error != nil ? "\(error!)" : "(no error)")

            if let data = data {
                if let response = try? JSONDecoder().decode(Response.self, from: data) {
                    if let series = response.data.series.first {
                        if let lastPoint = series.points.last {
                            dataStore.addPoints(
                                series.points.map({ DataPoint(date: $0.date, value: $0.value )})
                            )

                            logStore.log(message: "received_data (\(Int(lastPoint.value)))")

                            if date == nil {
                                dataStore.lastUpdateDate = Date()
                                NSLog("KrakowPiosDataLoader: saving data: %.0f at %@", lastPoint.value, "\(lastPoint.date)")
                            } else {
                                NSLog("KrakowPiosDataLoader: added data from %@", "\(date!)")
                            }

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
}
