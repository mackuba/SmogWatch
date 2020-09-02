//
//  InterfaceController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import CoreLocation
import Foundation
import os.log
import WatchKit

class InterfaceController: WKInterfaceController, CLLocationManagerDelegate {

    @IBOutlet var valueLabel: WKInterfaceLabel!
    @IBOutlet var valueCircle: WKInterfaceGroup!
    @IBOutlet var gradeLabel: WKInterfaceLabel!
    @IBOutlet var updatedAtLabel: WKInterfaceLabel!
    @IBOutlet var updatedAtRow: WKInterfaceGroup!
    @IBOutlet var chartView: WKInterfaceImage!
    @IBOutlet var stationNameLabel: WKInterfaceLabel!

    let dataStore = DataStore()
    let dataManager = DataManager()
    let dateFormatter = DateFormatter()
    let chartRenderer = ChartRenderer()
    let locationManager = CLLocationManager()

    let shortTimeFormat = DateFormatter.dateFormat(fromTemplate: "j:m", options: 0, locale: Locale.current)
    let longTimeFormat = DateFormatter.dateFormat(fromTemplate: "E j:m", options: 0, locale: Locale.current)

    var userLocation: CLLocation?

    override func awake(withContext context: Any?) {
        updateDisplayedData()
        updateStationInfo()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        NotificationCenter.default.addObserver(forName: DataStore.dataLoadedNotification, object: nil, queue: nil) { _ in
            self.updateDisplayedData()
        }
    }

    override func willActivate() {
        askForLocationIfNeeded()
    }

    func askForLocationIfNeeded() {
        guard userLocation == nil, CLLocationManager.locationServicesEnabled() else { return }

        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            break
        }
    }

    func updateDisplayedData() {
        var smogLevel: SmogLevel = .unknown
        var valueText = "?"

        if let updatedAt = dataStore.lastMeasurementDate {
            updatedAtRow.setHidden(false)

            dateFormatter.dateFormat = isSameDay(updatedAt) ? shortTimeFormat : longTimeFormat
            updatedAtLabel.setText(dateFormatter.string(from: updatedAt))

            if let amount = dataStore.currentLevel, Date().timeIntervalSince(updatedAt) < 6 * 3600 {
                smogLevel = SmogLevel.levelForValue(amount)
                valueText = String(Int(amount.rounded()))
            }
        } else {
            updatedAtRow.setHidden(true)
        }

        valueCircle.setBackgroundColor(smogLevel.color)
        valueLabel.setText(valueText)
        gradeLabel.setText(smogLevel.title)

        let points = dataStore.points
        let chartSize = CGSize(width: self.contentFrame.width, height: 65.0)

        if points.count >= 2, let chart = chartRenderer.generateChart(points: points, size: chartSize) {
            chartView.setImage(chart)
            chartView.setHidden(false)
        } else {
            chartView.setHidden(true)
        }
    }

    func updateStationInfo() {
        let channelId = dataStore.selectedChannelId

        if channelId != nil, let station = dataStore.stations.first(where: { $0.channelId == channelId }) {
            stationNameLabel.setText(station.name)
        } else {
            stationNameLabel.setText("not selected")
        }
    }

    func isSameDay(_ date: Date) -> Bool {
        let calendar = Calendar.current

        let updatedDay = calendar.component(.day, from: date)
        let currentDay = calendar.component(.day, from: Date())

        return updatedDay == currentDay
    }

    func setSelectedStation(_ station: Station) {
        dataStore.selectedChannelId = station.channelId
        stationNameLabel.setText(station.name)

        updateDisplayedData()
        gradeLabel.setText("Loading")

        dataManager.updateData()
    }

    func stationsSortedByDistance(from userLocation: CLLocation) -> [Station] {
        return dataStore.stations.sorted { (s1, s2) -> Bool in
            let d1 = CLLocation(latitude: s1.lat, longitude: s1.lng).distance(from: userLocation)
            let d2 = CLLocation(latitude: s2.lat, longitude: s2.lng).distance(from: userLocation)

            return d1 < d2
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        if segueIdentifier == "ChooseStation" {
            let stations: [Station]

            if let currentLocation = userLocation {
                stations = stationsSortedByDistance(from: currentLocation)
            } else {
                stations = dataStore.stations
            }

            return StationListContext(
                items: stations,
                selectedId: dataStore.selectedChannelId,
                userLocation: userLocation,
                onSelect: { station in
                    self.setSelectedStation(station)
                }
            )
        }

        return nil
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }

        userLocation = currentLocation

        if dataStore.selectedChannelId == nil {
            let closestStation = stationsSortedByDistance(from: currentLocation).first!
            setSelectedStation(closestStation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("CLLocationManager error: %{public}@", log: .ui, "\(error)")
    }
}
