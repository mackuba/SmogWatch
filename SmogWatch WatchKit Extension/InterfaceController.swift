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

    @IBOutlet var stationsSection: WKInterfaceGroup!
    @IBOutlet var stationNameLabel: WKInterfaceLabel!
    @IBOutlet var parameterNameLabel: WKInterfaceLabel!
    @IBOutlet var parameterButton: WKInterfaceButton!

    enum TextAlignment {
        case left, right, center
    }

    let dataStore = DataStore()
    let dateFormatter = DateFormatter()

    let shortTimeFormat = DateFormatter.dateFormat(fromTemplate: "H:mm", options: 0, locale: nil)
    let longTimeFormat = DateFormatter.dateFormat(fromTemplate: "E H:mm", options: 0, locale: nil)

    let leftChartMargin: CGFloat = 17
    let bottomChartMargin: CGFloat = 10
    let rightMargin: CGFloat = 10

    let chartFontAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.lightGray,
        .font: UIFont.systemFont(ofSize: 8.0)
    ]

    override func awake(withContext context: Any?) {
        stationsSection.setHidden(true)
        updateDisplayedData()

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(forName: DataStore.dataLoadedNotification, object: nil, queue: nil) { _ in
            self.updateDisplayedData()
        }

        notificationCenter.addObserver(forName: DataStore.configLoadedNotification, object: nil, queue: nil) { _ in
            self.updateDisplayedData()
            self.updateStationLabels()
            self.stationsSection.setHidden(false)
        }
    }

    override func willActivate() {
        if dataStore.lastConfigUpdateDate != nil {
            do {
                try dataStore.loadStations()
                updateStationLabels()
                stationsSection.setHidden(false)
            } catch let error {
                NSLog("Error loading stations: %@", "\(error)")
            }
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

        if points.count >= 2, let chart = generateChart(points: points) {
            chartView.setImage(chart)
            chartView.setHidden(false)
        } else {
            chartView.setHidden(true)
        }
    }

    func updateStationLabels() {
        let stationId = dataStore.selectedStationId

        if stationId != nil, let station = dataStore.stations.first(where: { $0.id == stationId }) {
            stationNameLabel.setText(station.name)
            parameterButton.setEnabled(true)
            parameterButton.setAlpha(1.0)
        } else {
            stationNameLabel.setText("not selected")
            parameterButton.setEnabled(false)
            parameterButton.setAlpha(0.4)
        }

        if let channel = dataStore.selectedChannel {
            parameterNameLabel.setText(channel.name)
        } else {
            parameterNameLabel.setText("not selected")
        }
    }

    func isSameDay(_ date: Date) -> Bool {
        let calendar = Calendar.current

        let updatedDay = calendar.component(.day, from: date)
        let currentDay = calendar.component(.day, from: Date())

        return updatedDay == currentDay
    }

    func generateChart(points: [DataPoint]) -> UIImage? {
        let width = self.contentFrame.width
        let height: CGFloat = 65.0
        let imageSize = CGSize(width: width, height: height)

        UIGraphicsBeginImageContextWithOptions(imageSize, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.move(to: CGPoint(x: leftChartMargin, y: 0))
        context.addLine(to: CGPoint(x: leftChartMargin, y: height - bottomChartMargin))
        context.addLine(to: CGPoint(x: width - rightMargin + 2, y: height - bottomChartMargin))
        context.drawPath(using: .stroke)

        let values = points.map { $0.value }
        let minValue = Int(values.min()!.rounded())
        let maxValue = Int(values.max()!.rounded())

        drawText(String(maxValue),
                 x: leftChartMargin - 2,
                 y: -2,
                 alignment: .right)
        drawText(String(minValue),
                 x: leftChartMargin - 2,
                 y: height - bottomChartMargin - 10,
                 alignment: .right)

        context.setLineWidth(1.0)
        context.setLineCap(.round)
        context.setLineJoin(.bevel)

        let firstPosition = chartPosition(forPointAt: 0, from: values, chartSize: imageSize)
        context.move(to: firstPosition)

        drawText(String(hour(for: points[0])),
                 x: firstPosition.x,
                 y: height - bottomChartMargin,
                 alignment: .center)

        for i in 1..<values.count {
            let position = chartPosition(forPointAt: i, from: values, chartSize: imageSize)
            context.addLine(to: position)

            drawText(String(hour(for: points[i])),
                     x: position.x,
                     y: height - bottomChartMargin,
                     alignment: .center)
        }

        context.setStrokeColor(UIColor.white.cgColor)
        context.drawPath(using: .stroke)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func drawText(_ text: String, x: CGFloat, y: CGFloat, alignment: TextAlignment = .left) {
        var leftPosition = x

        if alignment != .left {
            let textSize = text.size(withAttributes: chartFontAttributes)

            if alignment == .right {
                leftPosition -= ceil(textSize.width)
            } else {
                leftPosition -= ceil(textSize.width / 2)
            }
        }

        text.draw(at: CGPoint(x: leftPosition, y: y), withAttributes: chartFontAttributes)
    }

    func chartPosition(forPointAt index: Int, from values: [Double], chartSize: CGSize) -> CGPoint {
        let xPadding: CGFloat = 3
        let yPadding: CGFloat = 3
        let innerWidth = chartSize.width - leftChartMargin - 2 * xPadding - rightMargin
        let innerHeight = chartSize.height - bottomChartMargin - 2 * yPadding

        let minValue = values.min()!
        let maxValue = values.max()!

        let xOffset = innerWidth * CGFloat(index) / CGFloat(values.count - 1)
        let yOffset = innerHeight * CGFloat(values[index] - minValue) / CGFloat(maxValue - minValue)

        return CGPoint(
            x: leftChartMargin + xPadding + xOffset,
            y: chartSize.height - bottomChartMargin - yPadding - yOffset
        )
    }

    func hour(for point: DataPoint) -> Int {
        return Calendar.current.component(.hour, from: point.date)
    }

    func reloadAfterSelection() {
        updateStationLabels()
        updateDisplayedData()

        KrakowPiosDataLoader().fetchData { success in
            self.updateDisplayedData()
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        if segueIdentifier == "ChooseStation" {
            return SelectionListContext(
                items: dataStore.stations.sorted(by: { $0.name < $1.name }),
                selectedId: dataStore.selectedStationId,
                title: "Station",
                onSelect: { id in
                    self.dataStore.selectedStationId = id
                    self.reloadAfterSelection()
                }
            )
        } else if segueIdentifier == "ChoosePollutant" {
            let station = dataStore.stations.first(where: { $0.id == dataStore.selectedStationId })!
            let channels = station.channels.sorted(by: { $0.name < $1.name })

            return SelectionListContext(
                items: channels,
                selectedId: dataStore.selectedChannelId,
                title: "Pollutant",
                onSelect: { id in
                    self.dataStore.selectedChannel = channels.first(where: { $0.id == id })
                    self.reloadAfterSelection()
                }
            )
        }

        return nil
    }
}
