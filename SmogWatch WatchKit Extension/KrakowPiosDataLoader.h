//
//  KrakowPiosDataLoader.h
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 27.12.2018.
//  Copyright © 2018 Kuba Suder. Licensed under WTFPL license.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KrakowPiosDataLoader : NSObject

- (void)fetchDataWithCompletionHandler:(void(^)(void))handler;

@end

NS_ASSUME_NONNULL_END
