//
//  Logs.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 01.09.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import Foundation
import os.log

extension OSLog {
    static let subsystem = Bundle.main.bundleIdentifier!

    static let backgroundTask = OSLog(subsystem: subsystem, category: "Background task")
    static let lifecycle = OSLog(subsystem: subsystem, category: "Lifecycle")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
}
