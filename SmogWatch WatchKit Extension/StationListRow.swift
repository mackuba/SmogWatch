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
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    @IBOutlet weak var checkmark: WKInterfaceLabel!

    let measurementFormatter: MeasurementFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1

        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter = numberFormatter
        return measurementFormatter
    }()

    func showStation(_ station: Station) {
        titleLabel.setText(station.name)
        checkmark.setHidden(true)
    }

    func setCheckmarkVisible(_ visible: Bool) {
        checkmark.setHidden(!visible)
    }

    func setDistance(_ distance: Double) {
        let text = measurementFormatter.string(
            from: Measurement(value: distance, unit: UnitLength.meters)
        )
        distanceLabel.setText(text)
    }
}
