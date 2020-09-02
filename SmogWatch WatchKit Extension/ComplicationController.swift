//
//  ComplicationController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit
import os.log

private let MeasurementValidityTime = 3600 * 3
private let log = OSLog(subsystem: OSLog.subsystem, category: "Complication Controller")

class ComplicationController: NSObject, CLKComplicationDataSource {

    let dataStore = DataStore()


    // MARK: - Timeline Configuration

    func getSupportedTimeTravelDirections(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        os_log("getSupportedTimeTravelDirections() for complication %{public}@", log: log,
               complication.family.description);
        handler([])
    }


    // MARK: - Timeline Population

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler callback: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        os_log("getCurrentTimelineEntry() for complication %{public}@", log: log, complication.family.description)

        let entry: CLKComplicationTimelineEntry
        let handler = ComplicationHandlers.handler(for: complication)

        if let date = dataStore.lastMeasurementDate, let level = dataStore.currentLevel {
            let template = handler.template(for: level)
            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
            os_log("getCurrentTimelineEntry() -> %@ %.0f", log: log, date as NSDate, level)
        } else {
            let template = handler.templateForNoValue()
            entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            os_log("getCurrentTimelineEntry() -> %@ n/a", log: log, NSDate())
        }

        callback(entry)
    }


    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler callback: @escaping (CLKComplicationTemplate?) -> Void)
    {
        os_log("getLocalizableSampleTemplate() for complication %{public}@", log: log, complication.family.description)

        // This method will be called once per supported complication, and the results will be cached

        let handler = ComplicationHandlers.handler(for: complication)
        let template = handler.templateForSampleValue()

        callback(template)
    }
}
