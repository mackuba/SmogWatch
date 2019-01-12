//
//  CloudLogger.swift
//  SmogWatch
//
//  Created by Kuba Suder on 12.01.2019.
//  Copyright © 2019 Kuba Suder. Licensed under WTFPL license.
//

import Foundation

private let FileName = "smogwatch-log.txt"

class CloudLogger {
    static var shared = CloudLogger()

    let queue = DispatchQueue(label: "CloudLogger", qos: .utility)

    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZ"
        return df
    }()

    var logFile: FileHandle?

    init() {
        queue.async {
            let fileManager = FileManager.default

            if let iCloudFolder = fileManager.url(forUbiquityContainerIdentifier: nil) {
                let documents = iCloudFolder.appendingPathComponent("Documents")
                let fileURL = documents.appendingPathComponent(FileName)

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

    func log(text: String) {
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
