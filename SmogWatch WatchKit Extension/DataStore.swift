//
//  DataStore.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 22.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import Foundation

private let CurrentLevelKey = "CurrentLevel"
private let LastMeasurementDate = "LastMeasurementDate"
private let LastUpdateDate = "LastUpdateDate"

class DataStore {
    let defaults = UserDefaults.standard

    static let dataLoadedNotification = Notification.Name("DataLoadedNotification")

    var currentLevel: Double? {
        get {
            return defaults.object(forKey: CurrentLevelKey) as? Double
        }
        set {
            defaults.set(newValue, forKey: CurrentLevelKey)
        }
    }

    var lastUpdateDate: Date? {
        get {
            return defaults.object(forKey: LastUpdateDate) as? Date
        }
        set {
            defaults.set(newValue, forKey: LastUpdateDate)
        }
    }

    var lastMeasurementDate: Date? {
        get {
            return defaults.object(forKey: LastMeasurementDate) as? Date
        }
        set {
            defaults.set(newValue, forKey: LastMeasurementDate)
        }
    }
}
