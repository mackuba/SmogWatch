//
//  DataStore.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 06.03.2019.
//  Copyright © 2019 Kuba Suder. Licensed under WTFPL license.
//

import Foundation

private let CurrentLevelKey = "CurrentLevel"
private let LastMeasurementDate = "LastMeasurementDate"

class DataStore {
    let defaults = UserDefaults.standard

    var currentLevel: Double? {
        get { return defaults.object(forKey: CurrentLevelKey) as? Double }
        set { defaults.set(newValue, forKey: CurrentLevelKey) }
    }

    var lastMeasurementDate: Date? {
        get { return defaults.object(forKey: LastMeasurementDate) as? Date }
        set { defaults.set(newValue, forKey: LastMeasurementDate)}
    }
}
