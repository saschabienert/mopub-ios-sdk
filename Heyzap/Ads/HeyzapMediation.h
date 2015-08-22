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
#import "HZMediationStarter.h"
#import "HZMediationLoadManager.h"
#import "HZMediateRequester.h"
#import "HZMediationSettings.h"
#import "HZSegmentationController.h"

@protocol HZAdsDelegate;
@protocol HZIncentivizedAdDelegate;
@protocol HZBannerReportingDelegate;
@class HZBannerAdOptions;
@class HZMediationPersistentConfig;

@interface HeyzapMediation : NSObject <HZMediationAdapterDelegate, HZBannerReportingDelegate, HZMediationStarting, HZMediationLoadManagerDelegate, HZMediateRequesterDelegate>


@property (nonatomic, readonly) dispatch_queue_t pausableMainQueue;
@property (nonatomic, readonly) NSString *mediationId;
@property (nonatomic, readonly) HZMediationSettings *settings;
@property (nonatomic, readonly) HZSegmentationController *segmentationController;
@property (nonatomic, readonly) HZMediationPersistentConfig *persistentConfig;

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
- (id)underlyingDelegateForAdType:(HZAdType)adType;

- (void)setDelegate:(id)delegate forNetwork:(NSString *)network;
- (id)delegateForNetwork:(NSString *)network;

- (BOOL) isNetworkInitialized:(NSString *)network;
- (BOOL) isNetworkClassInitialized:(Class)networkClass;
- (BOOL)isAdapterInitialized:(HZBaseAdapter *)adapter;

- (void) setNetworkCallbackBlock: (void (^)(NSString *network, NSString *callback))block;
- (void) sendNetworkCallback: (NSString *) callback forNetwork: (NSString *) network;

- (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAdapter *adapter))completion;

- (void)pauseExpensiveWork;
- (void)resumeExpensiveWork;

- (void)showTestActivity;

@end
