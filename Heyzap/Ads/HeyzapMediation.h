//
//  HeyzapMediation.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"
#import "HZShowOptions.h"
#import "HZBannerAdapter.h"

@protocol HZAdsDelegate;
@protocol HZIncentivizedAdDelegate;
@protocol HZBannerReportingDelegate;
@class HZBannerAdOptions;

@interface HeyzapMediation : NSObject <HZMediationAdapterDelegate, HZBannerReportingDelegate>

+ (instancetype)sharedInstance;

#pragma mark - Setup

- (void)start;

#pragma mark - Showing Ads

- (void)fetchForAdType:(HZAdType)adType tag:(NSString *)tag additionalParams:(NSDictionary *)additionalParams completion:(void (^)(BOOL result, NSError *error))completion;

- (void)showAdForAdUnitType:(HZAdType)adType additionalParams:(NSDictionary *)additionalParams options:(HZShowOptions *)options;

- (BOOL)isAvailableForAdUnitType:(HZAdType)adType tag:(NSString *)tag;

// For use with the test activity.
- (BOOL)isAvailableForAdUnitType:(const HZAdType)adType tag:(NSString *)tag network:(HZBaseAdapter *const)network;

// Need Delegate API for getting the current view controller.
// We can handle the common scenarios by recursively finding the right view controller.

+ (BOOL)isOnlyHeyzapSDK;

/**
 *  Call this method to force `isOnlyHeyzapSDK` to always return `YES`.
 */
+ (void)forceOnlyHeyzapSDK;

+ (NSSet *)availableAdaptersWithHeyzap:(BOOL)includeHeyzap;
+ (NSSet *)availableNonHeyzapAdapters;

+ (NSString *)commaSeparatedAdapterList;

- (void)setDelegate:(id<HZAdsDelegate>)delegate forAdType:(HZAdType)adType;

- (void)setDelegate:(id)delegate forNetwork:(HZNetwork)network;
- (id)getDelegateForNetwork:(HZNetwork)network;

- (BOOL) isNetworkInitialized:(HZNetwork)network;

HZAdType hzAdTypeFromString(NSString *adUnit);
NSString * NSStringFromAdType(HZAdType type);

- (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAdapter *adapter))completion;

@end
