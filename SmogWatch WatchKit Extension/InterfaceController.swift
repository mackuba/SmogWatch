//
//  InterfaceController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {

    @IBOutlet var valueLabel: WKInterfaceLabel!
    @IBOutlet var valueCircle: WKInterfaceGroup!
    @IBOutlet var gradeLabel: WKInterfaceLabel!
    @IBOutlet var updatedAtLabel: WKInterfaceLabel!
    @IBOutlet var updatedAtRow: WKInterfaceGroup!
    @IBOutlet var chartView: WKInterfaceImage!
    @IBOutlet var stationNameLabel: WKInterfaceLabel!

    let dataStore = DataStore()
    let dateFormatter = DateFormatter()
    let chartRenderer = ChartRenderer()

    let shortTimeFormat = DateFormatter.dateFormat(fromTemplate: "H:mm", options: 0, locale: nil)
    let longTimeFormat = DateFormatter.dateFormat(fromTemplate: "E H:mm", options: 0, locale: nil)

    override func awake(withContext context: Any?) {
        updateDisplayedData()
        updateStationInfo()

        NotificationCenter.default.addObserver(forName: DataStore.dataLoadedNotification, object: nil, queue: nil) { _ in
            self.updateDisplayedData()
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

        KrakowPiosDataLoader().fetchData { success in
            self.updateDisplayedData()
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        if segueIdentifier == "ChooseStation" {
            return SelectionListContext(
                items: dataStore.stations,
                selectedId: dataStore.selectedChannelId,
                onSelect: { station in
                    self.setSelectedStation(station)
                }
            )
        }

        return nil
    }
}
