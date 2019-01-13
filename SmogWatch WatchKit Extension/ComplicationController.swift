//
//  ComplicationController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 15.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit

private let MeasurementValidityTime = 3600 * 3

// for logging
extension CLKComplicationFamily: CustomStringConvertible {
    public var description: String {
        switch self {
        case .circularSmall: return "circularSmall"
        case .extraLarge: return "extraLarge"
        case .graphicBezel: return "graphicBezel"
        case .graphicCircular: return "graphicCircular"
        case .graphicCorner: return "graphicCorner"
        case .graphicRectangular: return "graphicRectangular"
        case .modularLarge: return "modularLarge"
        case .modularSmall: return "modularSmall"
        case .utilitarianLarge: return "utilitarianLarge"
        case .utilitarianSmall: return "utilitarianSmall"
        case .utilitarianSmallFlat: return "utilitarianSmallFlat"
        }
    }
}

class ComplicationController: NSObject, CLKComplicationDataSource {

    let dataStore = DataStore()


    // MARK: - Timeline Configuration

    func getSupportedTimeTravelDirections(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        NSLog("ComplicationController: getSupportedTimeTravelDirections() for complication %@",
              complication.family.description);
        // does this matter at all anymore with Time Travel gone now? ¯\_(ツ)_/¯
        handler([.forward])
    }

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        let expirationTime =
            dataStore.lastMeasurementDate?.addingTimeInterval(TimeInterval(MeasurementValidityTime))

        NSLog("ComplicationController: getTimelineEndDate() for complication %@ -> %@",
              complication.family.description,
              expirationTime != nil ? "\(expirationTime!)" : "nil");

        handler(expirationTime)
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
