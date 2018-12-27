//
//  ComplicationHandler.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 27.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

import ClockKit

private let PMTitleText = "PM10"
private let PMShortTitleText = "PM"
private let PlaceholderText = "–"
private let SampleValueText = "50"

protocol ComplicationHandler {
    func template(for value: Double) -> CLKComplicationTemplate
    func templateForNoValue() -> CLKComplicationTemplate
    func templateForSampleValue() -> CLKComplicationTemplate
}

extension ComplicationHandler {
    func integerValue(_ value: Double) -> Int {
        return Int(value.rounded())
    }

    func integerText(_ value: Double) -> String {
        return String(integerValue(value))
    }
}

enum ComplicationHandlers {
    static func handler(for complication: CLKComplication) -> ComplicationHandler {
        switch complication.family {
        case .circularSmall:
            return CircularSmall()
        case .modularSmall:
            return ModularSmall()
        default:
            preconditionFailure("Complication family not supported")
        }
    }

    class CircularSmall: ComplicationHandler {
        func template(for value: Double) -> CLKComplicationTemplate {
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: integerText(value))
            return template
        }

        func templateForNoValue() -> CLKComplicationTemplate {
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: PlaceholderText)
            return template
        }

        func templateForSampleValue() -> CLKComplicationTemplate {
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: SampleValueText)
            return template
        }
    }

    class ModularSmall: ComplicationHandler {
        func template(for value: Double) -> CLKComplicationTemplate {
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMTitleText, shortText: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: integerText(value))
            return template
        }

        func templateForNoValue() -> CLKComplicationTemplate {
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMTitleText, shortText: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: PlaceholderText)
            return template
        }

        func templateForSampleValue() -> CLKComplicationTemplate {
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: PMTitleText, shortText: PMShortTitleText)
            template.line2TextProvider = CLKSimpleTextProvider(text: SampleValueText)
            return template
        }
    }
}
