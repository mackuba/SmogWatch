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

    @IBOutlet var valueCircle: WKInterfaceGroup!
    @IBOutlet var valueLabel: WKInterfaceLabel!
    @IBOutlet var gradeLabel: WKInterfaceLabel!
    @IBOutlet var updatedAtLabel: WKInterfaceLabel!
    @IBOutlet var updatedAtRow: WKInterfaceGroup!
    @IBOutlet var chartView: WKInterfaceImage!
    @IBOutlet var stationNameLabel: WKInterfaceLabel!

    let dataStore = DataStore()
    let dateFormatter = DateFormatter()
    let chartRenderer = ChartRenderer()

    let shortTimeFormat = DateFormatter.dateFormat(
      fromTemplate: "j:m", options: 0, locale: Locale.current
    )
    let longTimeFormat = DateFormatter.dateFormat(
      fromTemplate: "E j:m", options: 0, locale: Locale.current
    )

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        updateDisplayedData()
        updateStationInfo()

        NotificationCenter.default.addObserver(
            forName: DataStore.dataLoadedNotification,
            object: nil,
            queue: nil
        ) { _ in
            self.updateDisplayedData()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        if segueIdentifier == "ChooseStation" {
            return StationListContext(
                items: dataStore.stations,
                selectedId: dataStore.selectedChannelId,
                onSelect: { station in
                    self.setSelectedStation(station)
                }
            )
        }

        return nil
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
        guard let channelId = dataStore.selectedChannelId else { return }

        if let station = dataStore.stations.first(where: { $0.channelId == channelId }) {
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

        KrakowPiosDataLoader().fetchData { success in
            self.updateDisplayedData()
        }
    }
}
