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

@protocol HZMetricsProtocol <NSObject>

@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSString *adUnit;

@end

@class HZAdModel;

@interface HZMetrics : NSObject

+ (HZMetrics *) sharedInstance;


#pragma mark - Logging Metrics

- (void) logMetricsEvent: (NSString *) eventName value:(id)value withObject:(id <HZMetricsProtocol>)object;
- (void) logTimeSinceFetchFor: (NSString *) eventName withObject:(id <HZMetricsProtocol>)object;
- (void) logFetchTimeWithObject: (id <HZMetricsProtocol>)object;
- (void) logShowAdWithObject: (id <HZMetricsProtocol>)object;
- (void) logTimeSinceShowAdFor:(NSString *)eventname withObject:(id <HZMetricsProtocol>)object;
- (void) logDownloadPercentageFor:(NSString *)eventname withObject:(id <HZMetricsProtocol>)object;
- (void) logTimeSinceStartFor:(NSString *)eventname withObject:(id <HZMetricsProtocol>)object;

- (void)logIsAvailable:(BOOL)isAvailable withObject:(id <HZMetricsProtocol>)object;



- (void) removeAdWithObject:(id <HZMetricsProtocol>)object;

//- (void)logFetchResultsForTag:(HZAdModel *)ad error:(NSError *)error;

/**
 *  Call this method when downloading a video to record current download progress.
 *
 *  @param downloadPercentage % completion for the download
 *  @param object             an object that has tag and adUnit properties
 */
- (void)setDownloadPercentage:(int)downloadPercentage withObject:(id <HZMetricsProtocol>)object;

@end
