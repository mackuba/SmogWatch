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

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        NSLog("InterfaceController: awake(withContext:)")

        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        NSLog("InterfaceController: willActivate()")
    }

    override func didAppear() {
        super.didAppear()

        NSLog("InterfaceController: didAppear()")
    }

    override func willDisappear() {
        super.willDisappear()

        NSLog("InterfaceController: willDisappear()")
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()

        NSLog("InterfaceController: didDeactivate()")
    }
}
