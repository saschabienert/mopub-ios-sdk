//
//  HZMetrics.h
//  Heyzap
//
//  Created by Noah Goetz on 7/22/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString *const kIsAvailableCalledKey;
extern NSString *const kFetchKey;
extern NSString *const kFetchFailedKey;
extern NSString *const kFetchFailReasonKey;
extern NSString *const kShowAdResultKey;
extern NSString *const kAdFailedToLoadValue;
extern NSString *const kIsAvailablePercentDownloadedKey;
extern NSString *const kIsAvailableTimeSincePreviousFetchKey;
extern NSString *const kShowAdTimeSincePreviousRelevantFetchKey;


@class HZAdModel;

@interface HZMetrics : NSObject

+ (HZMetrics *) sharedInstance;


#pragma mark - Logging Metrics

- (void) logMetricsEvent: (NSString *) eventName value:(id)value tag:(NSString *)tag type:(NSString *)type;
- (void) logTimeSinceFetchFor: (NSString *) eventName tag:(NSString *)tag type:(NSString *)type;
- (void) logFetchTimeForTag: (NSString *) tag type:(NSString *) type;
- (void) logShowAdForTag: (NSString *) tag type: (NSString *) type;
- (void) logTimeSinceShowAdFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type;
- (void) logDownloadPercentageFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type;
- (void) logTimeSinceStartFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type;

- (void)logIsAvailable:(BOOL)isAvailable tag:(NSString *)tag type:(NSString *)type;



- (void) removeAdForTag:(NSString *)tag type:(NSString *)type;

//- (void)logFetchResultsForTag:(HZAdModel *)ad error:(NSError *)error;

/**
 *  Call this method when downloading a video to record current download progress.
 *
 *  @param downloadPercentage % completion for the download
 *  @param tag                the tag being downloaded for
 *  @param type               the ad unit being downloaded for
 */
- (void)setDownloadPercentage:(int)downloadPercentage tag:(NSString *)tag type:(NSString *)type;

@end
