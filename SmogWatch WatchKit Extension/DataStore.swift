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
private let lastConfigUpdateDateKey = "LastConfigUpdateDate"

private let pointsCount = 8

struct DataPoint {
    let date: Date
    let value: Double
}

struct DataStation: Codable {
    let id: Int
    let name: String

    let channels: [DataChannel]
}

struct DataChannel: Codable {
    let id: Int
    let name: String
    let shortName: String
    let veryShortName: String
}

class DataStore {
    let defaults = UserDefaults.standard

    static let dataLoadedNotification = Notification.Name("DataLoadedNotification")
    static let configLoadedNotification = Notification.Name("ConfigLoadedNotification")

    private(set) var stations: [DataStation] = []

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

    var lastConfigUpdateDate: Date? {
        get {
            return defaults.object(forKey: lastConfigUpdateDateKey) as? Date
        }
        set {
            defaults.set(newValue, forKey: lastConfigUpdateDateKey)
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

    func stationsFileName() throws -> URL {
        let dataDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return dataDirectory.appendingPathComponent("stations.data")
    }

    func loadStations() throws {
        let data = try Data(contentsOf: stationsFileName())
        self.stations = try PropertyListDecoder().decode([DataStation].self, from: data)
    }

    func saveStations(_ stations: [DataStation]) throws {
        self.stations = stations

        let data = try PropertyListEncoder().encode(stations)
        try data.write(to: stationsFileName())
    }
}
