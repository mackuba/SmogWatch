//
//  KrakowPiosDataLoader.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 06.03.2019.
//  Copyright © 2019 Kuba Suder. Licensed under WTFPL license.
//

import Foundation

private let DataURL = "http://monitoring.krakow.pios.gov.pl/dane-pomiarowe/pobierz"

class KrakowPiosDataLoader {
    let dateFormatter: DateFormatter = {
        let d = DateFormatter()

        // not sure if this is needed, but just to be safe
        // see https://developer.apple.com/library/archive/qa/qa1480/
        d.locale = Locale(identifier: "en_US_POSIX")

        d.dateFormat = "dd.MM.yyyy"

        // make sure we use CET timezone - if you're e.g. in Moscow
        // and you ask for '19.02.2019' on 19 Feb after midnight
        // (still 18 Feb in Poland), you'll get no data
        d.timeZone = TimeZone(identifier: "Europe/Warsaw")!

        return d
    }()

    // explained below
    let dataStore = DataStore()

    let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = 10.0
        return URLSession(configuration: config)
    }()

    func queryString() -> String {
        let query: [String: Any] = [
            "measType": "Auto",
            "viewType": "Parameter",
            "dateRange": "Day",
            "date": dateFormatter.string(from: Date()),

            // hardcoded ID for PM10 on a specific station
            // we'll make it configurable later
            "viewTypeEntityId": "pm10",
            "channels": [148]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: query, options: [])
        let json = String(data: jsonData, encoding: .utf8)!

        // don't ask me, that's what the API expects
        return "query=\(json)"
    }

    func fetchData(_ completion: @escaping (Bool) -> ()) {
        var request = URLRequest(url: URL(string: DataURL)!)
        request.httpBody = queryString().data(using: .utf8)!
        request.httpMethod = "POST"

        NSLog("KrakowPiosDataLoader: sending request to %@ with %@ ...",
              DataURL, queryString())

        let task = session.dataTask(with: request) { (data, response, error) in
            var success = false

            if let error = error {
                NSLog("KrakowPiosDataLoader: received error: %@", "\(error)")
            } else {
                NSLog("KrakowPiosDataLoader: received response: %@",
                      data != nil ? "\(data!.count) bytes" : "(nil)")
            }

            if let data = data {
                if let obj = try? JSONSerialization.jsonObject(with: data, options: []) {
                    if let json = obj as? [String: Any] {
                        if let data = json["data"] as? [String: Any] {
                            if let series = data["series"] as? [[String: Any]] {

                                // there would be more than one data series if we passed
                                // multiple "channel IDs" (e.g. for more than 1 station)
                                if let first = series.first {
                                    if let points = first["data"] as? [[String]] {

                                        // the data series is an array of up to 26 hourly
                                        // measurements; we only take the last one for now
                                        if let point = points.last {
                                            let date = Date(
                                                timeIntervalSince1970: Double(point[0])!
                                            )
                                            let value = Double(point[1])!

                                            self.dataStore.currentLevel = value
                                            self.dataStore.lastMeasurementDate = date

                                            NSLog("KrakowPiosDataLoader: saving data: " +
                                                "%.0f at %@", value, "\(date)")

                                            success = true
                                        }
                                    }
                                }
                            }
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
