//
//  ExtensionDelegate.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import os.log
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let dataManager = DataManager()

    func applicationDidFinishLaunching() {
        os_log("ExtensionDelegate: applicationDidFinishLaunching() [%{public}@]", log: .lifecycle,
               WKExtension.shared().applicationState.description)

        scheduleNextReload(log: .lifecycle)
    }

    func applicationWillEnterForeground() {
        os_log("ExtensionDelegate: applicationWillEnterForeground()", log: .lifecycle)
    }

    func applicationDidBecomeActive() {
        os_log("ExtensionDelegate: applicationDidBecomeActive()", log: .lifecycle)

        dataManager.updateDataIfNeeded()
    }

    func applicationWillResignActive() {
        os_log("ExtensionDelegate: applicationWillResignActive()", log: .lifecycle)
    }

    func applicationDidEnterBackground() {
        os_log("ExtensionDelegate: applicationDidEnterBackground()", log: .lifecycle)
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.

        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                os_log("ExtensionDelegate: handling WKApplicationRefreshBackgroundTask [%{public}@]",
                       log: .backgroundTask,
                       WKExtension.shared().applicationState.description)

                scheduleNextReload(log: .backgroundTask)

                dataManager.updateData { success in
                    os_log("ExtensionDelegate: completed WKApplicationRefreshBackgroundTask", log: .backgroundTask)
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                os_log("ExtensionDelegate: received WKSnapshotRefreshBackgroundTask, reason: %{public}@ [%{public}@]",
                       log: .backgroundTask,
                       snapshotTask.reasonForSnapshot.description, WKExtension.shared().applicationState.description)

                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date.distantFuture,
                    userInfo: nil
                )

            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                os_log("ExtensionDelegate: received WKWatchConnectivityRefreshBackgroundTask", log: .backgroundTask)
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                os_log("ExtensionDelegate: received WKURLSessionRefreshBackgroundTask", log: .backgroundTask)
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                os_log("ExtensionDelegate: received unknown task", log: .backgroundTask, type: .fault)
                task.setTaskCompletedWithSnapshot(false)
            }
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

    func scheduleNextReload(log: OSLog) {
        let targetDate = nextReloadTime(after: Date())

        os_log("ExtensionDelegate: scheduling next update at %@", targetDate as NSDate)

        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: targetDate,
            userInfo: nil,
            scheduledCompletion: { error in
                // contrary to what the docs say, this is called when the task is scheduled, i.e. immediately
                os_log("ExtensionDelegate: background task %{public}@", log: log,
                       error == nil ? "scheduled successfully" : "NOT scheduled: \(error!)")
            }
        )
    }
}
