//
//  DataManager.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.06.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit
import Foundation
import os.log

private let minimumIntervalBetweenUpdates: TimeInterval = 5 * 60
private let log = OSLog(subsystem: OSLog.subsystem, category: "DataManager")

class DataManager {
    let loader = KrakowPiosDataLoader()
    let dataStore = DataStore()

    var canUpdateDataNow: Bool {
        if let lastUpdate = dataStore.lastUpdateDate {
            return Date().timeIntervalSince(lastUpdate) > minimumIntervalBetweenUpdates
        } else {
            return true
        }
    }

    func updateDataIfNeeded() {
        if canUpdateDataNow {
            updateData()
        } else {
            os_log("Not loading data since it was last updated at %@", log: log, dataStore.lastUpdateDate! as NSDate)
        }
    }

    func updateData(callback: ((Bool) -> ())? = nil) {
        loader.fetchData { success in
            NotificationCenter.default.post(name: DataStore.dataLoadedNotification, object: nil)

            if success {
                self.reloadComplications()
            }

            if self.dataStore.hasEnoughPoints {
                callback?(success)
            } else {
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())

                self.loader.fetchData(date: yesterday) { success in
                    NotificationCenter.default.post(name: DataStore.dataLoadedNotification, object: nil)
                    callback?(success)
                }
            }
        }
    }

    func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()

        os_log("Requesting reload of complications", log: log)

        for complication in server.activeComplications ?? [] {
            os_log("- %{public}@", log: log, complication.family.description)
            server.reloadTimeline(for: complication)
        }
    }
}
