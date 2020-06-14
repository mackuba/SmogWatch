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
    @IBOutlet weak var checkmark: WKInterfaceLabel!

    func setTitle(_ title: String) {
        titleLabel.setText(title)
    }

    func setCheckmarkVisible(_ visible: Bool) {
        checkmark.setHidden(!visible)
    }
}
