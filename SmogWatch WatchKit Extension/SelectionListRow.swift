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

    let measurementFormatter: MeasurementFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1

        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter = numberFormatter
        return measurementFormatter
    }()

    func setTitle(_ title: String) {
        titleLabel.setText(title)
    }

    func setDistance(_ distance: Double) {
        let text = measurementFormatter.string(from: Measurement(value: distance, unit: UnitLength.meters))
        distanceLabel.setText(text)
    }

    func setCheckmarkVisible(_ visible: Bool) {
        checkmark.setHidden(!visible)
    }
}
