//
//  DataStore.h
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 27.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

#import <Foundation/Foundation.h>

@interface DataStore : NSObject

@property (nonatomic, assign) double currentLevel;
@property (nonatomic, strong) NSDate *lastMeasurementDate;

@end
