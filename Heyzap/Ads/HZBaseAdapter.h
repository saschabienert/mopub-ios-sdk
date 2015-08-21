//
//  HZBaseAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZShowOptions.h"
#import "HZBannerAdapter.h"
#import "HZAdapterDelegate.h"
#import "HZCreativeType.h"
#import "HZAdType.h"

@import UIKit;

@class HZBaseAdapter;
@class HZBannerAdapter;
@class HZBannerAdOptions;
@class HZAdapterDelegate;
@protocol HZBannerReportingDelegate;

@protocol HZMediationAdapterDelegate <NSObject>

- (void)adapterDidShowAd:(HZBaseAdapter *)adapter;
- (void)adapterWasClicked:(HZBaseAdapter *)adapter;
- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter;

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter;
- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter;

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter;
- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter;

- (void)adapterDidFailToShowAd:(HZBaseAdapter *)adapter error:(NSError *)underlyingError;

@end

/**
 *  The (mostly abstract) superclass for adapters.
 */
@interface HZBaseAdapter : NSObject

/**
 *  These properties exist for subclasses to use. Other callers must use `lastErrorForAdType:` and `clearErrorForAdType:`.
 */
@property (nonatomic, strong) NSError *lastStaticError;
@property (nonatomic, strong) NSError *lastIncentivizedError;
@property (nonatomic, strong) NSError *lastVideoError;

@property (nonatomic, weak) id<HZMediationAdapterDelegate>delegate;

@property (nonatomic, strong) NSDictionary *credentials;

@property (nonatomic, strong) HZAdapterDelegate *forwardingDelegate;



+ (instancetype)sharedInstance;

- (void)prefetchForCreativeType:(HZCreativeType)creativeType;

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType;

- (NSNumber *) latestMediationScoreForCreativeType:(HZCreativeType)creativeType;
- (void) setLatestMediationScore:(NSNumber *)score forCreativeType:(HZCreativeType)creativeType;

/**
 *  The adapter should show an ad for the given ad type.
 *
 *  @param creativeType The type of ad (video, incentivized, static) to show
 *  @param options Options to configure showing the ad
 */
- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options;

- (HZCreativeType)supportedCreativeTypes;

- (BOOL)isVideoOnlyNetwork;

+ (NSString *)name;

+ (NSString *)humanizedName;

/**
 *  The version of the SDK, if available.
 *
 *  @return The version string, or `nil` if it wasn't available.
 */
+ (NSString *)sdkVersion;

+ (BOOL)isSDKAvailable;

/**
 *  Enable the adapter with the given adapter-specific credentials.
 *
 * @param credentials The credentials necessary for the adapter to start the SDK.
 *
 *  Note: do all SDK-specific initialization here, not in init or sharedInstance. The adapter instance can exist before the SDK is enabled.
 */
+ (NSError *)enableWithCredentials:(NSDictionary *)credentials;

#pragma mark - Banners

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate;
- (BOOL)hasBannerCredentials;

#pragma mark - Inferred methods

- (NSString *)sdkVersion;

- (NSString *)name;

- (BOOL)supportsCreativeType:(HZCreativeType)creativeType;

- (NSError *)lastErrorForCreativeType:(HZCreativeType)creativeType;

/**
 *  Its possible this should be handled internally by the adapters, like when they fetch...
 *
 *  @param adType The type of ad to clear the error for.
 */
- (void)clearErrorForCreativeType:(HZCreativeType)creativeType;

#pragma mark - Implemented methods

+ (Class)adapterClassForName:(NSString *)adapterName;

+ (NSSet *)allAdapterClasses;
+ (NSArray *)testActivityAdapters;

+ (BOOL)isHeyzapAdapter;

/**
 *  Subclasses can override.
 *  @return The amount of time to wait, in seconds, between asking if this adapter has an ad. Increase this value for adapters/SDKs whose `isAvailable` calls are expensive, and decrease it for adapters/SDKs whose calls are inexpensive.
 */
+ (NSTimeInterval)isAvailablePollInterval;

/**
 *  Returns a bitmask of all supported HZAdTypes (keeping blended interstitials in mind) derived from the adapters `supportedCreativeTypes` method.
 */
- (HZAdType) possibleSupportedAdTypes;

@end
