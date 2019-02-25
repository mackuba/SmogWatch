//
//  ExtensionDelegate.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

private let MinimumIntervalBetweenUpdates: TimeInterval = 5 * 60

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let loader = KrakowPiosDataLoader()
    let dataStore = DataStore()

    var canUpdateDataNow: Bool {
        if let lastUpdate = dataStore.lastUpdateDate {
            return Date().timeIntervalSince(lastUpdate) > MinimumIntervalBetweenUpdates
        } else {
            return true
        }
    }

    func applicationDidFinishLaunching() {
        NSLog("ExtensionDelegate: applicationDidFinishLaunching() [\(WKExtension.shared().applicationState)]")

        scheduleNextReload()
    }

    func applicationWillEnterForeground() {
        NSLog("ExtensionDelegate: applicationWillEnterForeground()")
    }

    func applicationDidBecomeActive() {
        NSLog("ExtensionDelegate: applicationDidBecomeActive()")

        if canUpdateDataNow {
            KrakowPiosDataLoader().fetchData { success in
                if success {
                    self.reloadActiveComplications()
                }
            }
        } else {
            NSLog("ExtensionDelegate: not loading data since it was last updated at \(dataStore.lastUpdateDate!)")
        }
    }

    func applicationWillResignActive() {
        NSLog("ExtensionDelegate: applicationWillResignActive()")

        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func applicationDidEnterBackground() {
        NSLog("ExtensionDelegate: applicationDidEnterBackground()")
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                NSLog("ExtensionDelegate: handling WKApplicationRefreshBackgroundTask")

                scheduleNextReload()

                KrakowPiosDataLoader().fetchData { success in
                    if success {
                        self.reloadActiveComplications()
                    }

                    NSLog("ExtensionDelegate: completed WKApplicationRefreshBackgroundTask")
                    // Be sure to complete the background task once you’re done.
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                NSLog("ExtensionDelegate: received WKSnapshotRefreshBackgroundTask, reason: %@",
                      snapshotTask.reasonForSnapshot.description)

                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                NSLog("ExtensionDelegate: received WKWatchConnectivityRefreshBackgroundTask")
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                NSLog("ExtensionDelegate: received WKURLSessionRefreshBackgroundTask")
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                NSLog("ExtensionDelegate: received unknown task")
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    func reloadActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()

        NSLog("ExtensionDelegate: requesting reload of complications")
        for complication in server.activeComplications ?? [] {
            NSLog("- %@", complication.family.description)
            server.reloadTimeline(for: complication)
        }
    }

    func nextReloadTime(after date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let targetMinutes = DateComponents(minute: 15)

        // find next 15 minutes past the hour
        var nextReloadTime = calendar.nextDate(after: date, matching: targetMinutes, matchingPolicy: .nextTime)!

        // but if it's in less than 5 minutes, then skip this one and try next hour
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
            scheduledCompletion: { error in
                // contrary to what the docs say, this is called when the task is scheduled, i.e. immediately
                NSLog("ExtensionDelegate: background task %@",
                      error == nil ? "scheduled successfully" : "NOT scheduled: \(error!)")
            }
        )
    }
}
