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

@protocol HZAdsDelegate;
@protocol HZIncentivizedAdDelegate;

@interface HeyzapMediation : NSObject <HZMediationAdapterDelegate>

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

HZAdType hzAdTypeFromString(NSString *adUnit);
NSString * NSStringFromAdType(HZAdType type);

- (HZBannerAdapter *)getBannerWithRootViewController:(UIViewController *const)viewController sizeOptions:(NSDictionary *)sizeOptions;

@end
