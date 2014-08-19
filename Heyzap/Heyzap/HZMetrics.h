//
//  HZMetrics.h
//  Heyzap
//
//  Created by Noah Goetz on 7/22/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZMetrics : NSObject

+ (HZMetrics *) sharedInstance;
- (void) logMetricsEvent: (NSString *) eventName value:(id)value tag:(NSString *)tag type:(NSString *)type;
- (void) logTimeSinceFetchFor: (NSString *) eventName tag:(NSString *)tag type:(NSString *)type;
- (void) logFetchTimeForTag: (NSString *) tag type:(NSString *) type;
- (void) logShowAdForTag: (NSString *) tag type: (NSString *) type;
- (void) logTimeSinceShowAdFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type;
- (void) logDownloadPercentageFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type;
- (void) logTimeSinceStartFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type;
- (void) removeAdForTag:(NSString *)tag type:(NSString *)type;
- (void) sendCachedMetrics;

@property (nonatomic) int downloadPercentage;

@end
