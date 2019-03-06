//
//  ExtensionDelegate.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        NSLog("ExtensionDelegate: applicationDidFinishLaunching()")

        scheduleNextReload()

        KrakowPiosDataLoader().fetchData { success in
            if success {
                self.reloadActiveComplications()
            }
        }
    }

    func reloadActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()

        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }

    func nextReloadTime(after date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let targetMinutes = DateComponents(minute: 15)

        var nextReloadTime = calendar.nextDate(
            after: date,
            matching: targetMinutes,
            matchingPolicy: .nextTime
        )!

        // if it's in less than 5 minutes, then skip this one and try next hour
        if nextReloadTime.timeIntervalSince(date) < 5 * 60 {
            nextReloadTime.addTimeInterval(3600)
        }

        return nextReloadTime
    }

    func scheduleNextReload() {
        let targetDate = nextReloadTime(after: Date())

        NSLog("ExtensionDelegate: scheduling next update at %@", "\(targetDate)")

        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: targetDate,
            userInfo: nil,
            scheduledCompletion: { _ in }
        )
    }

    /*func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }*/

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                NSLog("ExtensionDelegate: handling WKApplicationRefreshBackgroundTask")

                scheduleNextReload()

                KrakowPiosDataLoader().fetchData { success in
                    if success {
                        self.reloadActiveComplications()
                    }

                    NSLog("ExtensionDelegate: completed WKApplicationRefreshBackgroundTask")
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }

            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
