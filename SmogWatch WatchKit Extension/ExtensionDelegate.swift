//
//  ExtensionDelegate.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

let Logger = CloudLogger(fileName: "smogwatch-log-watchos.txt")

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let loader = KrakowPiosDataLoader()

    func applicationDidFinishLaunching() {
        Logger.log("ExtensionDelegate: applicationDidFinishLaunching()")

        // always fetch data on startup, so that we have some way of manually force reloading it
        KrakowPiosDataLoader().fetchData { success in
            if success {
                self.reloadActiveComplications()
            }

            self.scheduleNextReload()
        }
    }

    func applicationDidBecomeActive() {
        Logger.log("ExtensionDelegate: applicationDidBecomeActive()")

        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        Logger.log("ExtensionDelegate: applicationWillResignActive()")

        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                Logger.log("ExtensionDelegate: handling WKApplicationRefreshBackgroundTask")

                KrakowPiosDataLoader().fetchData { success in
                    if success {
                        self.reloadActiveComplications()
                    }

                    self.scheduleNextReload()

                    Logger.log("ExtensionDelegate: completed WKApplicationRefreshBackgroundTask")
                    // Be sure to complete the background task once you’re done.
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                Logger.log("ExtensionDelegate: received WKSnapshotRefreshBackgroundTask")
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                Logger.log("ExtensionDelegate: received WKWatchConnectivityRefreshBackgroundTask")
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                Logger.log("ExtensionDelegate: received WKURLSessionRefreshBackgroundTask")
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                Logger.log("ExtensionDelegate: received unknown task")
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    func reloadActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()

        Logger.log("ExtensionDelegate: requesting reload of complications")
        for complication in server.activeComplications ?? [] {
            Logger.log("- \(complication.family)")
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

        Logger.log("ExtensionDelegate: scheduling next update at \(targetDate)")

        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: targetDate,
            userInfo: nil,
            scheduledCompletion: { _ in
                Logger.log("ExtensionDelegate: background refresh task callback block called")
            }
        )
    }
}
