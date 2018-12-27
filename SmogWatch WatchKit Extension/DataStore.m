//
//  DataStore.m
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 27.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

#import "DataStore.h"

static NSString *CurrentLevelKey = @"CurrentLevel";
static NSString *LastMeasurementDate = @"LastMeasurementDate";

@implementation DataStore

- (double)currentLevel {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:CurrentLevelKey];
}

- (void)setCurrentLevel:(double)level {
    [[NSUserDefaults standardUserDefaults] setDouble:level forKey:CurrentLevelKey];
}

- (NSDate *)lastMeasurementDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:LastMeasurementDate];
}

- (void)setLastMeasurementDate:(NSDate *)date {
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:LastMeasurementDate];
}

@end
