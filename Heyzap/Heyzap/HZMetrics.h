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
extern NSString *const kNetworkKey;
extern NSString *const kNetworkVersionKey;
extern NSString *const kOrdinalKey;
extern NSString *const kAdUnitKey;
extern NSString *const kConnectivityKey;
extern NSString *const kFetchDownloadTimeKey;
extern NSString *const kTimeFromStartToShowAdKey;
extern NSString *const kShowAdTimeTillAdIsDisplayedKey;
extern NSString *const kShowAdPercentageDownloadedKey;
extern NSString *const kAdClickedKey;
extern NSString *const kCloseClickedKey;
extern NSString *const kTimeClickedKey;
extern NSString *const kNthAdKey;
extern NSString *const kTimeFromFetchToImpressionKey;
extern NSString *const kVideoSizeKey;
extern NSString *const kVideoHostKey;
extern NSString *const kVideoPathKey;
extern NSString *const kVideoDownloadTimeKey;
extern NSString *const kVideoNotDownloadedButInterstitialShownValue;
extern NSString *const kFullyCachedValue;
extern NSString *const kNoConnectivityValue;
extern NSString *const kNoAdAvailableValue;
extern NSString *const kAdAlreadyDisplayedValue;
extern NSString *const kNotCachedAndNotAFetchableAdUnitValue;
extern NSString *const kNotCachedAndAttemptedFetchFailedValue;
extern NSString *const kNotCachedAndAttemptedFetchSuccessValue;



@protocol HZMetricsProvider <NSObject>

@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSString *adUnit;

@end

@class HZAdModel;

@interface HZMetrics : NSObject

+ (HZMetrics *) sharedInstance;


#pragma mark - Logging Metrics

- (void) logMetricsEvent: (NSString *) eventName value:(id)value withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;
- (void) logTimeSinceFetchFor: (NSString *) eventName withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;
- (void) logFetchTimeWithObject: (id <HZMetricsProvider>)provider network:(NSString *)network;
- (void) logShowAdWithObject: (id <HZMetricsProvider>)provider network:(NSString *)network;
- (void) logTimeSinceShowAdFor:(NSString *)eventname withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;
- (void) logDownloadPercentageFor:(NSString *)eventname withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;
- (void) logTimeSinceStartFor:(NSString *)eventname withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;

- (void)logIsAvailable:(BOOL)isAvailable withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;



- (void) removeAdWithProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;

//- (void)logFetchResultsForTag:(HZAdModel *)ad error:(NSError *)error;

/**
 *  Call this method when downloading a video to record current download progress.
 *
 *  @param downloadPercentage % completion for the download
 *  @param provider           an object that has tag and adUnit properties
 */
- (void)setDownloadPercentage:(int)downloadPercentage withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network;

@end
