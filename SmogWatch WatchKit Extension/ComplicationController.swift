//
//  ComplicationController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit

private let MeasurementValidityTime = 3600 * 3
private let PMTitleText = "PM10"
private let PMShortTitleText = "PM"
private let PlaceholderText = "–"
private let SampleValueText = "50"


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
            let valueText = String(Int(level.rounded()))

            switch complication.family {
            case .circularSmall:
                let template = CLKComplicationTemplateCircularSmallStackText()
                template.line1TextProvider = CLKSimpleTextProvider(text: PMShortTitleText)
                template.line2TextProvider = CLKSimpleTextProvider(text: valueText)

                entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)

            case .modularSmall:
                let template = CLKComplicationTemplateModularSmallStackText()
                template.line1TextProvider = CLKSimpleTextProvider(text: PMTitleText, shortText: PMShortTitleText)
                template.line2TextProvider = CLKSimpleTextProvider(text: valueText)

                entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)

            default:
                preconditionFailure("Complication family not supported")
            }
        } else {
            switch complication.family {
            case .circularSmall:
                let template = CLKComplicationTemplateCircularSmallStackText()
                template.line1TextProvider = CLKSimpleTextProvider(text: PMShortTitleText)
                template.line2TextProvider = CLKSimpleTextProvider(text: PlaceholderText)

                entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)

            case .modularSmall:
                let template = CLKComplicationTemplateModularSmallStackText()
                template.line1TextProvider = CLKSimpleTextProvider(text: PMTitleText, shortText: PMShortTitleText)
                template.line2TextProvider = CLKSimpleTextProvider(text: PlaceholderText)

                entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)

            default:
                preconditionFailure("Complication family not supported")
            }
        }

        handler(entry)
    }


    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void)
    {
        // This method will be called once per supported complication, and the results will be cached

        switch complication.family {
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: SampleValueText)
            handler(template)

        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMTitleText, shortText: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: SampleValueText)
            handler(template)

        default:
            preconditionFailure("Complication family not supported")
        }
    }
}
