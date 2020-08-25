//
//  ChartRenderer.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 25.08.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

class ChartRenderer {

    let chartFontAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.lightGray,
        .font: UIFont.systemFont(ofSize: 8.0)
    ]

    let leftMargin: CGFloat = 17
    let bottomMargin: CGFloat = 10
    let rightMargin: CGFloat = 10

    enum TextAlignment {
        case left, right, center
    }

    func drawText(_ text: String, x: CGFloat, y: CGFloat, alignment: TextAlignment = .left) {
        var leftPosition = x

        if alignment != .left {
            let width = text.size(withAttributes: chartFontAttributes).width
            leftPosition -= (alignment == .right) ? ceil(width) : ceil(width / 2)
        }

        text.draw(at: CGPoint(x: leftPosition, y: y), withAttributes: chartFontAttributes)
    }

    func generateChart(points: [DataPoint], size chartSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(chartSize, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        let width = chartSize.width
        let height = chartSize.height

        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.move(to: CGPoint(x: leftMargin, y: 0))
        context.addLine(to: CGPoint(x: leftMargin, y: height - bottomMargin))
        context.addLine(to: CGPoint(x: width - rightMargin + 2, y: height - bottomMargin))
        context.drawPath(using: .stroke)

        let values = points.map { $0.value }
        let minValue = Int(values.min()!.rounded())
        let maxValue = Int(values.max()!.rounded())

        drawText(String(maxValue),
                 x: leftMargin - 2,
                 y: -2,
                 alignment: .right)
        drawText(String(minValue),
                 x: leftMargin - 2,
                 y: height - bottomMargin - 10,
                 alignment: .right)

        context.setLineWidth(1.0)
        context.setLineCap(.round)
        context.setLineJoin(.bevel)

        let firstPosition = chartPosition(forPointAt: 0, from: values, chartSize: chartSize)
        context.move(to: firstPosition)

        drawText(String(hour(for: points[0])),
                 x: firstPosition.x,
                 y: height - bottomMargin,
                 alignment: .center)

        for i in 1..<values.count {
            let position = chartPosition(forPointAt: i, from: values, chartSize: chartSize)
            context.addLine(to: position)

            drawText(String(hour(for: points[i])),
                     x: position.x,
                     y: height - bottomMargin,
                     alignment: .center)
        }

        context.setStrokeColor(UIColor.white.cgColor)
        context.drawPath(using: .stroke)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    func chartPosition(forPointAt index: Int, from values: [Double], chartSize: CGSize) -> CGPoint {
        let xPadding: CGFloat = 3
        let yPadding: CGFloat = 3
        let innerWidth = chartSize.width - leftMargin - 2 * xPadding - rightMargin
        let innerHeight = chartSize.height - bottomMargin - 2 * yPadding

        let minValue = values.min()!
        let maxValue = values.max()!

        let xOffset = innerWidth * CGFloat(index) / CGFloat(values.count - 1)
        let yOffset = innerHeight * CGFloat(values[index] - minValue) / CGFloat(maxValue - minValue)

        return CGPoint(
            x: leftMargin + xPadding + xOffset,
            y: chartSize.height - bottomMargin - yPadding - yOffset
        )
    }

    func hour(for point: DataPoint) -> Int {
        return Calendar.current.component(.hour, from: point.date)
    }}
