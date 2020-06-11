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

    let dataStore = DataStore()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        updateDisplayedData()

        NotificationCenter.default.addObserver(forName: DataStore.dataLoadedNotification, object: nil, queue: nil) { _ in
            self.updateDisplayedData()
        }
    }

    func updateDisplayedData() {
        let smogLevel: SmogLevel

        if let amount = dataStore.currentLevel {
            let displayedValue = Int(amount.rounded())
            valueLabel.setText(String(displayedValue))
            smogLevel = SmogLevel.levelForValue(amount)
        } else {
            valueLabel.setText("?")
            smogLevel = .unknown
        }

        valueCircle.setBackgroundColor(smogLevel.color)
        gradeLabel.setText(smogLevel.title)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
