//
//  LogStore.swift
//  WeatherWatch WatchKit Extension
//
//  Created by Kuba Suder on 26.08.2020.
//  Copyright © 2020 Kuba Suder. All rights reserved.
//

import CoreLocation
import Foundation

private let logsKey = "GeneralLogs"

let logStore = LogStore()

struct Log {
    let date: Date
    let message: String
}

class LogStore: ObservableObject {
    let defaults = UserDefaults.standard

    @Published private(set) var logs: [Log]

    init() {
        let array = defaults.object(forKey: logsKey) as? [[Any]] ?? []

        logs = array.map { item in
            return Log(
                date: item[0] as! Date,
                message: item[1] as! String
            )
        }
    }

    func log(message: String) {
        logs.append(Log(date: Date(), message: message))
        saveLogs()
    }

    func saveLogs() {
        let array = logs.map { log in
            return [log.date, log.message]
        }

        defaults.set(array, forKey: logsKey)
    }
}
