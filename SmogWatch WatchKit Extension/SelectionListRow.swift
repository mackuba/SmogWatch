//
//  SelectionListRow.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 13.06.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

class SelectionListRow: NSObject {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    @IBOutlet weak var checkmark: WKInterfaceLabel!
    @IBOutlet weak var mainGroup: WKInterfaceGroup!

    let defaultInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
    let checkmarkInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 15)

    func setTitle(_ title: String) {
        titleLabel.setText(title)
    }

    func setDistance(_ distance: Double) {
        let s = String(format: "%.1f km", distance / 1000)
        distanceLabel.setText(s)
    }

    func setCheckmarkVisible(_ visible: Bool) {
        checkmark.setHidden(!visible)
        mainGroup?.setContentInset(visible ? checkmarkInsets : defaultInsets)
    }
}
