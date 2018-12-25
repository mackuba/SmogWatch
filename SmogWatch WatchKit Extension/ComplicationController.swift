//
//  ComplicationController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit

let MeasurementValidityTime = 3600 * 3


class ComplicationController: NSObject, CLKComplicationDataSource {

    let dataStore = DataStore()


    // MARK: - Timeline Configuration

    func getSupportedTimeTravelDirections(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        handler([])
    }

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(dataStore.lastMeasurementDate?.addingTimeInterval(TimeInterval(MeasurementValidityTime)))
    }


    // MARK: - Timeline Population

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        let entry: CLKComplicationTimelineEntry

        if let date = dataStore.lastMeasurementDate, let level = dataStore.currentLevel {
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PM10")
            template.line2TextProvider = CLKSimpleTextProvider(text: String(Int(level.rounded())))
            template.highlightLine2 = false

            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
        } else {
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PM10")
            template.line2TextProvider = CLKSimpleTextProvider(text: "–")

            entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        }

        handler(entry)
    }


    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void)
    {
        // This method will be called once per supported complication, and the results will be cached
        let template = CLKComplicationTemplateModularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "PM10")
        template.line2TextProvider = CLKSimpleTextProvider(text: "50")

        handler(template)
    }
}
