//
//  SmogLevel.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 11.06.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import Foundation
import UIKit

enum SmogLevel: Int, CaseIterable {
    case great = 30,
        good = 50,
        poor = 75,
        prettyBad = 100,
        reallyBad = 150,
        horrible = 200,
        extremelyBad = 10000,
        unknown = -1

    static func levelForValue(_ value: Double) -> SmogLevel {
        let levels = SmogLevel.allCases
        return levels.first(where: { Double($0.rawValue) >= value }) ?? .unknown
    }

    var title: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .poor: return "Poor"
        case .prettyBad: return "Pretty Bad"
        case .reallyBad: return "Really Bad"
        case .horrible: return "Horrible"
        case .extremelyBad: return "Extremely Bad"
        case .unknown: return "Unknown"
        }
    }

    var color: UIColor {
        let hue: CGFloat

        switch self {
        case .great: hue = 120
        case .good: hue = 80
        case .poor: hue = 55
        case .prettyBad: hue = 35
        case .reallyBad: hue = 10
        case .horrible: hue = 0
        case .extremelyBad: hue = 280
        case .unknown: hue = 0
        }

        if self == .unknown {
            return UIColor.lightGray
        } else {
            return UIColor(hue: hue/360, saturation: 0.95, brightness: 0.9, alpha: 1.0)
        }
    }
}
