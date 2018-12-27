//
//  ComplicationController.m
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 27.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

#import "ComplicationController.h"
#import "DataStore.h"

static NSTimeInterval MeasurementValidityTime = 3600 * 3;
static NSString *PMTitleText = @"PM10";
static NSString *PMShortTitleText = @"PM";
static NSString *PlaceholderText = @"–";
static NSString *SampleValueText = @"50";

@interface ComplicationController () {
    DataStore *dataStore;
}

@end

@implementation ComplicationController

- (instancetype)init {
    self = [super init];
    if (self) {
        dataStore = [[DataStore alloc] init];
    }
    return self;
}


#pragma mark - Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication
                                            withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
    handler(0);
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication
                              withHandler:(void(^)(NSDate * __nullable date))handler {
    handler([[dataStore lastMeasurementDate] dateByAddingTimeInterval:MeasurementValidityTime]);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication
                                   withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
    CLKComplicationTimelineEntry *entry;

    if (dataStore.lastMeasurementDate && dataStore.currentLevel) {
        NSString *valueText = [NSString stringWithFormat:@"%d", (NSInteger) round(dataStore.currentLevel)];

        CLKComplicationTemplateModularSmallStackText *template = [[CLKComplicationTemplateModularSmallStackText alloc] init];
        template.line1TextProvider = [CLKSimpleTextProvider textProviderWithText:PMTitleText shortText:PMShortTitleText];
        template.line2TextProvider = [CLKSimpleTextProvider textProviderWithText:valueText];

        entry = [CLKComplicationTimelineEntry entryWithDate:dataStore.lastMeasurementDate complicationTemplate:template];
    } else {
        CLKComplicationTemplateModularSmallStackText *template = [[CLKComplicationTemplateModularSmallStackText alloc] init];
        template.line1TextProvider = [CLKSimpleTextProvider textProviderWithText:PMTitleText shortText:PMShortTitleText];
        template.line2TextProvider = [CLKSimpleTextProvider textProviderWithText:PlaceholderText];

        entry = [CLKComplicationTimelineEntry entryWithDate:[NSDate date] complicationTemplate:template];
    }

    handler(entry);
}


#pragma mark - Placeholder Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication
                                        withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
    // This method will be called once per supported complication, and the results will be cached
    CLKComplicationTemplateModularSmallStackText *template = [[CLKComplicationTemplateModularSmallStackText alloc] init];
    template.line1TextProvider = [CLKSimpleTextProvider textProviderWithText:PMTitleText shortText:PMShortTitleText];
    template.line2TextProvider = [CLKSimpleTextProvider textProviderWithText:SampleValueText];

    handler(template);
}

@end
