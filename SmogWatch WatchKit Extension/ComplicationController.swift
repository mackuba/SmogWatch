//
//  ComplicationController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit

private let MeasurementValidityTime = 3600 * 3

class ComplicationController: NSObject, CLKComplicationDataSource {

    let dataStore = DataStore()


    // MARK: - Timeline Configuration

    func getSupportedTimeTravelDirections(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        NSLog("ComplicationController: getSupportedTimeTravelDirections() for complication %@",
              complication.family.description);
        handler([])
    }


    // MARK: - Timeline Population

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler callback: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        NSLog("ComplicationController: getCurrentTimelineEntry() for complication %@",
              complication.family.description)

        let entry: CLKComplicationTimelineEntry
        let handler = ComplicationHandlers.handler(for: complication)

        if let date = dataStore.lastMeasurementDate, let level = dataStore.currentLevel {
            let template = handler.template(for: level)
            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
            NSLog("ComplicationController: getCurrentTimelineEntry() -> %@ %.0f", "\(date)", level)
        } else {
            let template = handler.templateForNoValue()
            entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            NSLog("ComplicationController: getCurrentTimelineEntry() -> %@ n/a", "\(Date())")
        }

        callback(entry)
    }


    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler callback: @escaping (CLKComplicationTemplate?) -> Void)
    {
        NSLog("ComplicationController: getLocalizableSampleTemplate() for complication %@",
              complication.family.description)

        // This method will be called once per supported complication, and the results will be cached

        let handler = ComplicationHandlers.handler(for: complication)
        let template = handler.templateForSampleValue()

        callback(template)
    }
}
