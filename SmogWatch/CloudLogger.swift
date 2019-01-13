//
//  CloudLogger.swift
//  SmogWatch
//
//  Created by Kuba Suder on 12.01.2019.
//  Copyright © 2019 Kuba Suder. Licensed under WTFPL license.
//

import Foundation

/*
   Tips:
   1) enable iCloud in Capabilities, for both iOS and WatchKit extension targets (iCloud Documents only)
   2) enable the same container iCloud.eu.mackuba.SmogWatch in both targets
   3) add a key NSUbiquitousContainers in both Info.plists, with a dictionary entry iCloud.eu.mackuba.SmogWatch,
      and in that dictionary add NSUbiquitousContainerIsDocumentScopePublic => true; without this, you will see
      a container with some data in "Manage iCloud Storage", but not on icloud.com / Files.app / Mac Finder
   4) if you've run the app once with iCloud enabled but without that Info.plist config, you need to increase the
      bundle version number for the change to be recognized (and it needs to be the same in all targets)
   5) it works in the iOS simulator, just remember to log in to iCloud in the settings (just like on a real device),
      otherwise url(forUbiquityContainerIdentifier:) will return nil
*/        

class CloudLogger {
    let queue = DispatchQueue(label: "CloudLogger", qos: .utility)

    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZ"
        return df
    }()

    var logFile: FileHandle?

    init(fileName: String) {
        queue.async {
            let fileManager = FileManager.default

            // get the location of the local iCloud Drive folder for the app
            if let iCloudFolder = fileManager.url(forUbiquityContainerIdentifier: nil) {

                // we need to create a "Documents" subdirectory and put our stuff there
                // only things in that directory are visible in iCloud Drive in Finder on Mac
                let documents = iCloudFolder.appendingPathComponent("Documents")
                let fileURL = documents.appendingPathComponent(fileName)

                if !fileManager.fileExists(atPath: fileURL.path) {
                    fileManager.createFile(atPath: fileURL.path, contents: nil)
                }

                do {
                    let handle = try FileHandle(forWritingTo: fileURL)
                    handle.seekToEndOfFile()
                    self.logFile = handle
                } catch let error {
                    NSLog("CloudLogger: error creating a file handle: \(error)")
                }
            } else {
                NSLog("CloudLogger: iCloud folder not available :(")
            }
        }
    }

    func log(_ text: String) {
        let now = Date()

        queue.async {
            if let file = self.logFile {
                let timestamp = self.dateFormatter.string(from: now)
                let line = "\(timestamp) \(text)\n"

                file.write(line.data(using: .utf8)!)
                file.synchronizeFile()
            }

            NSLog("%@", text)
        }
    }
}
