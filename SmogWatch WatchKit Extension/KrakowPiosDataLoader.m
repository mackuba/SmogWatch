//
//  KrakowPiosDataLoader.m
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 27.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

#import <ClockKit/ClockKit.h>

#import "DataStore.h"
#import "KrakowPiosDataLoader.h"

static NSString *DataURL = @"http://monitoring.krakow.pios.gov.pl/dane-pomiarowe/pobierz";

@implementation KrakowPiosDataLoader

- (void)fetchDataWithCompletionHandler:(void(^)(void))handler {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"dd.MM.yyyy";

    NSDictionary *query = @{
        @"measType": @"Auto",
        @"viewType": @"Parameter",
        @"dateRange": @"Day",
        @"date": [dateFormatter stringFromDate:[NSDate date]],
        @"viewTypeEntityId": @"pm10",
        @"channels": @[@148]
    };

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:query options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:DataURL]];
    [request setHTTPBody:[[NSString stringWithFormat:@"query=%@", json] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];

    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                        completionHandler:^(NSData * _Nullable data,
                                                            NSURLResponse * _Nullable response,
                                                            NSError * _Nullable error) {
        if (data) {
            NSDictionary *jo = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (jo) {
                NSArray *sdlast = [[jo[@"data"][@"series"] firstObject][@"data"] lastObject];
                if (sdlast) {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[sdlast[0] doubleValue]];
                    double val = [sdlast[1] doubleValue];

                    DataStore *ds = [[DataStore alloc] init];
                    ds.currentLevel = val;
                    ds.lastMeasurementDate = date;

                    id comp = [[[CLKComplicationServer sharedInstance] activeComplications] firstObject];
                    if (comp) {
                        [[CLKComplicationServer sharedInstance] reloadTimelineForComplication:comp];
                    }
                }
            }
        }

        handler();
    }];

    [task resume];
}

@end
