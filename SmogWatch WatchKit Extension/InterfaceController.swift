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

        if points.count >= 2, let chart = generateChart(points: points) {
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
