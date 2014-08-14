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
- (NSMutableDictionary *) getMetricsForTag:(NSString *)tag andType:(NSString *)type;
- (void) logMetricsEvent: (NSString *) eventName withValue:(id)value forTag:(NSString *)tag andType:(NSString *)type;
- (void) logTimeSinceFetchFor: (NSString *) eventName forTag:(NSString *)tag andType:(NSString *)type;
- (void) logFetchTimeForTag: (NSString *) tag andType:(NSString *) type;
- (void) logShowAdForTag: (NSString *) tag andType: (NSString *) type;
- (void) logTimeSinceShowAdFor:(NSString *)eventname forTag:(NSString *)tag andType:(NSString *)type;
- (void) logDownloadPercentageFor:(NSString *)eventname forTag:(NSString *)tag andType:(NSString *)type;
- (void) logTimeSinceStartFor:(NSString *)eventname forTag:(NSString *)tag andType:(NSString *)type;
- (void) removeAdForTag:(NSString *)tag andType:(NSString *)type;
- (void) cacheMetrics;
- (void) sendCachedMetrics;

@property (nonatomic) int downloadPercentage;

@end
