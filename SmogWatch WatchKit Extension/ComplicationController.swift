//
//  ComplicationController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        handler([])
    }
    
    /*func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }*/
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        let store = DataStore()
        let entry: CLKComplicationTimelineEntry
        let date: Date
        let valueLabel: String

        if let lastMeasurement = store.lastMeasurementDate, let level = store.currentLevel {
            valueLabel = String(Int(level.rounded()))
            date = lastMeasurement
        } else {
            valueLabel = "--"
            date = Date()
        }

        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PM10")
            template.line2TextProvider = CLKSimpleTextProvider(text: valueLabel)
            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)

        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PM")
            template.line2TextProvider = CLKSimpleTextProvider(text: valueLabel)
            entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)

        default:
            preconditionFailure("Complication family not supported")
        }

        handler(entry)
    }
    
    /*func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }*/
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void)
    {
        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PM10")
            template.line2TextProvider = CLKSimpleTextProvider(text: "50")
            handler(template)

        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PM")
            template.line2TextProvider = CLKSimpleTextProvider(text: "50")
            handler(template)

        default:
            preconditionFailure("Complication family not supported")
        }
    }
}
