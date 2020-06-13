//
//  WatchKitExtensions.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 30.01.2019.
//  Copyright © 2019 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit
import WatchKit

extension CLKComplicationFamily: CustomStringConvertible {
    public var description: String {
        switch self {
        case .circularSmall: return "circularSmall"
        case .extraLarge: return "extraLarge"
        case .graphicBezel: return "graphicBezel"
        case .graphicCircular: return "graphicCircular"
        case .graphicCorner: return "graphicCorner"
        case .graphicRectangular: return "graphicRectangular"
        case .modularLarge: return "modularLarge"
        case .modularSmall: return "modularSmall"
        case .utilitarianLarge: return "utilitarianLarge"
        case .utilitarianSmall: return "utilitarianSmall"
        case .utilitarianSmallFlat: return "utilitarianSmallFlat"
        @unknown default: return "(unknown)"
        }
    }
}

extension WKApplicationState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active: return "active"
        case .background: return "background"
        case .inactive: return "inactive"
        @unknown default: return "(unknown)"
        }
    }
}

extension WKSnapshotReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .appBackgrounded: return "appBackgrounded"
        case .appScheduled: return "appScheduled"
        case .complicationUpdate: return "complicationUpdate"
        case .prelaunch: return "prelaunch"
        case .returnToDefaultState: return "returnToDefaultState"
        @unknown default: return "(unknown)"
        }
    }
}
