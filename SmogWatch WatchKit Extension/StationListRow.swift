//
//  StationListRow.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 09.09.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

class StationListRow: NSObject {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var checkmark: WKInterfaceLabel!

    func showStation(_ station: Station) {
        titleLabel.setText(station.name)
        checkmark.setHidden(true)
    }

    func setCheckmarkVisible(_ visible: Bool) {
        checkmark.setHidden(!visible)
    }
}
