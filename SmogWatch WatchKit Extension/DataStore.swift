//
//  DataStore.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 22.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import Foundation

private let savedPointsKey = "SavedPoints"
private let lastUpdateDateKey = "LastUpdateDate"
private let selectedChannelIdKey = "SelectedChannelId"

private let pointsCount = 8

struct DataPoint {
    let date: Date
    let value: Double
}

struct Station: Codable {
    let channelId: Int
    let name: String
    let lat: Double
    let lng: Double
}

class DataStore {
    let defaults = UserDefaults.standard

    static let dataLoadedNotification = Notification.Name("DataLoadedNotification")

    lazy var stations: [Station] = loadStations()

    var selectedChannelId: Int? {
        get {
            return defaults.object(forKey: selectedChannelIdKey) as? Int
        }
        set {
            if newValue != selectedChannelId {
                defaults.set(newValue, forKey: selectedChannelIdKey)
                invalidateData()
            }
        }
    }

    func invalidateData() {
        defaults.removeObject(forKey: savedPointsKey)
        defaults.removeObject(forKey: lastUpdateDateKey)
    }

    var currentLevel: Double? {
        get {
            return points.last?.value
        }
    }

    var lastMeasurementDate: Date? {
        get {
            return points.last?.date
        }
    }

    var lastUpdateDate: Date? {
        get {
            return defaults.object(forKey: lastUpdateDateKey) as? Date
        }
        set {
            defaults.set(newValue, forKey: lastUpdateDateKey)
        }
    }

    var points: [DataPoint] {
        get {
            guard let tuples = defaults.object(forKey: savedPointsKey) as? [[Any]] else {
                return []
            }

            return tuples.compactMap { t in
                if t.count == 2, let date = t[0] as? Date, let value = t[1] as? Double {
                    return DataPoint(date: date, value: value)
                } else {
                    return nil
                }
            }
        }
    }

    func addPoints(_ newPoints: [DataPoint]) {
        var pointMap: [Date:DataPoint] = [:]

        self.points.forEach { p in pointMap[p.date] = p }
        newPoints.forEach { p in pointMap[p.date] = p }

        let allPoints = pointMap.keys.sorted().map { date in pointMap[date]! }
        let recentPoints = Array(allPoints.suffix(pointsCount))
        let encodedData = recentPoints.map { p in [p.date, p.value ]}

        defaults.set(encodedData, forKey: savedPointsKey)
    }

    func loadStations() -> [Station] {
        let stationsFile = Bundle.main.url(forResource: "Stations", withExtension: "plist")!
        let data = try! Data(contentsOf: stationsFile)

        return try! PropertyListDecoder().decode([Station].self, from: data)
    }
}
