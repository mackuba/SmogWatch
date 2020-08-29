//
//  DataManager.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.06.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit
import Foundation

private let minimumIntervalBetweenUpdates: TimeInterval = 5 * 60

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
            NSLog("DataManager: not loading data since it was last updated at \(dataStore.lastUpdateDate!)")
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

        NSLog("DataManager: requesting reload of complications")

        let complications = server.activeComplications
        logStore.log(message: "reloading \(complications != nil ? "\(complications!.count)" : "?") complications")

        for complication in complications ?? [] {
            NSLog("- %@", complication.family.description)
            server.reloadTimeline(for: complication)
        }
    }
}
