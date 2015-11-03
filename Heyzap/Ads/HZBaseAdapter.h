//
//  HZBaseAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZShowOptions.h"
#import "HZFetchOptions.h"
#import "HZBannerAdapter.h"
#import "HZAdapterDelegate.h"
#import "HZCreativeType.h"
#import "HZAdType.h"
#import "HZMediationAdAvailabilityDataProvider.h"

#import <UIKit/UIKit.h>

@class HZBaseAdapter;
@class HZBannerAdapter;
@class HZBannerAdOptions;
@class HZAdapterDelegate;
@protocol HZBannerReportingDelegate;

@protocol HZMediationAdapterDelegate <NSObject>

- (void)adapterDidShowAd:(nonnull HZBaseAdapter *)adapter;
- (void)adapterWasClicked:(nonnull HZBaseAdapter *)adapter;
- (void)adapterDidDismissAd:(nonnull HZBaseAdapter *)adapter;

- (void)adapterDidCompleteIncentivizedAd:(nonnull HZBaseAdapter *)adapter;
- (void)adapterDidFailToCompleteIncentivizedAd:(nonnull HZBaseAdapter *)adapter;

- (void)adapterWillPlayAudio:(nonnull HZBaseAdapter *)adapter;
- (void)adapterDidFinishPlayingAudio:(nonnull HZBaseAdapter *)adapter;

- (void)adapterDidFailToShowAd:(nonnull HZBaseAdapter *)adapter error:(nullable NSError *)underlyingError;

@end

/**
 *  The (mostly abstract) superclass for adapters.
 */
@interface HZBaseAdapter : NSObject

@property (nonatomic, weak) id<HZMediationAdapterDelegate>delegate;

/**
 *  The credentials should be set on adapters immediately after calling sharedAdapter. Subclasses should ignore attempts to call this property's setter method if their credentials have already been set.
 */
@property (nonatomic, strong, nullable) NSDictionary *credentials;

@property (nonatomic, strong, nullable) HZAdapterDelegate *forwardingDelegate;

@property (nonatomic, readonly) BOOL isInitialized;


+ (nullable instancetype)sharedAdapter;

- (nullable NSString *)testActivityInstructions;

- (void)prefetchAdWithMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider;

- (BOOL)hasAdWithMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider;

- (nonnull NSNumber *) latestMediationScoreForCreativeType:(HZCreativeType)creativeType;
- (void) setLatestMediationScore:(nullable NSNumber *)score forCreativeType:(HZCreativeType)creativeType;

/**
 *  The adapter should show an ad for the given ad type. Don't call this method unless you've called `hasAdWithMetadata:` and it returned `YES`.
 *
 *  @param creativeType The type of ad (video, incentivized, static) to show
 *  @param options Options to configure showing the ad
 */
- (void)showAdWithOptions:(nonnull HZShowOptions *)options;

- (HZCreativeType)supportedCreativeTypes;

+ (nonnull NSString *)name;

+ (nonnull NSString *)humanizedName;

/**
 *  The version of the SDK, if available.
 *
 *  @return The version string, or `nil` if it isn't available.
 */
+ (nullable NSString *)sdkVersion;

+ (BOOL)isSDKAvailable;

/**
 *  Initialize the 3rd party SDK using the credentials it already has. This method should return an error if the SDK couldn't be initialized because it was missing a critical credential.
 */
- (nullable NSError *)initializeSDK;

#pragma mark - Banners

- (nullable HZBannerAdapter *)fetchBannerWithOptions:(nonnull HZBannerAdOptions *)options reportingDelegate:(nullable id<HZBannerReportingDelegate>)reportingDelegate;

#pragma mark - Inferred methods

- (nullable NSString *)sdkVersion;

- (nonnull NSString *)name;
- (nonnull NSString *)humanizedName;

- (BOOL)supportsCreativeType:(HZCreativeType)creativeType;




- (BOOL) hasNecessaryCredentials;

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType; // For networks that have multiple, optional credentials. This must be called after the network has been initialized.
// Maybe pass credentials immediately on creating the instance, and store them there?
// I really dislike how it's no longer possible to statically tell whether a network has been initialized or not.

/**
 *  Returns the last error the adapter received from the adapted SDK when fetching with the given ad metadata (creativeType, tag, placement ID override, etc.). The default implementation sorts errors only using creativeType, but subclasses can override this method to their needs.
 */
- (nullable NSError *)lastFetchErrorForAdsWithMatchingMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider;

#pragma mark - Implemented methods

+ (nullable Class)adapterClassForName:(nonnull NSString *)adapterName;

+ (nonnull NSSet *)allAdapterClasses;
+ (nonnull NSArray *)testActivityAdapters;

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
