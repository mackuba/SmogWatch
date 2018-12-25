//
//  KrakowPiosDataLoader.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 23.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import Foundation
import ClockKit

private let DataURL = "http://monitoring.krakow.pios.gov.pl/dane-pomiarowe/pobierz"

class KrakowPiosDataLoader {
    let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.locale = Locale(identifier: "en_US_POSIX")
        d.dateFormat = "dd.MM.yyyy"
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

    func fetchData(completion: @escaping (Bool) -> ()) {
        var request = URLRequest(url: URL(string: DataURL)!)
        request.httpBody = queryString().data(using: .utf8)!
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            var success = false

            if let data = data {
                if let jo = try? JSONSerialization.jsonObject(with: data, options: []) {
                    if let json = jo as? [String:Any] {
                        if let data = json["data"] as? [String:Any] {
                            if let series = data["series"] as? [[String:Any]] {
                                if let s1 = series.first {
                                    if let sd = s1["data"] as? [[String]] {
                                        if let sdlast = sd.last {
                                            let date = Date(timeIntervalSince1970: Double(sdlast[0])!)
                                            let val = Double(sdlast[1])

                                            self.dataStore.currentLevel = val
                                            self.dataStore.lastMeasurementDate = date

                                            success = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            completion(success)
        }

        task.resume()
    }
}
