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
@property (nonatomic, strong) NSError *lastInterstitialError;
@property (nonatomic, strong) NSError *lastIncentivizedError;
@property (nonatomic, strong) NSError *lastVideoError;

@property (nonatomic, weak) id<HZMediationAdapterDelegate>delegate;

/**
 *  The credentials should be set on adapters immediately after calling sharedInstance. Subclasses should ignore attempts to call this method if their credentials have already been set.
 */
@property (nonatomic, strong) NSDictionary *credentials;

/**
 *  Do not call this method directly. Subclasses should implement this method to read their credentials dictionary (`self.credentials`) into properties. The default implementation of this method does nothing, so can be left unimplemented for networks like iAds that don't have credentials.
 */
- (void)loadCredentials;

@property (nonatomic, strong) HZAdapterDelegate *forwardingDelegate;



+ (instancetype)sharedInstance;

- (void)prefetchForType:(HZAdType)type;

- (BOOL)hasAdForType:(HZAdType)type;

- (NSNumber *) latestMediationScoreForAdType:(HZAdType) adType;
- (void) setLatestMediationScore:(NSNumber *)score forAdType:(HZAdType)adType;

/**
 *  The adapter should show an ad for the given ad type.
 *
 *  @param type The type of ad (video, incentivized, interstitial) to show
 *  @param options Options to configure showing the ad
 */
- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options;

- (HZAdType)supportedAdFormats;

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
 *  Initialize the 3rd party SDK using the credentials it already has. This method should return an error if the SDK couldn't be initialized because it was missing a critical credential.
 */
- (NSError *)initializeSDK;

#pragma mark - Banners

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate;

#pragma mark - Inferred methods

- (NSString *)sdkVersion;

- (NSString *)name;

- (BOOL)supportsAdType:(HZAdType)adType;

- (BOOL)hasCredentialsForAdType:(HZAdType)adType; // For networks that have multiple, optional credentials. This must be called after the network has been initialized.
// Maybe pass credentials immediately on creating the instance, and store them there?
// I really dislike how it's no longer possible to statically tell whether a network has been initialized or not.

- (NSError *)lastErrorForAdType:(HZAdType)adType;

/**
 *  Its possible this should be handled internally by the adapters, like when they fetch...
 *
 *  @param adType The type of ad to clear the error for.
 */
- (void)clearErrorForAdType:(HZAdType)adType;

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

@end
