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
    func fetchData(completion: @escaping () -> ()) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd.MM.yyyy"

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

        var request = URLRequest(url: URL(string: DataURL)!)
        request.httpBody = "query=\(json)".data(using: .utf8)!
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
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

                                            let dsds = DataStore()
                                            dsds.currentLevel = val
                                            dsds.lastMeasurementDate = date

                                            if let comp = CLKComplicationServer.sharedInstance().activeComplications?.first {
                                                CLKComplicationServer.sharedInstance().reloadTimeline(for: comp)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            completion()
        }

        task.resume()
    }
}
