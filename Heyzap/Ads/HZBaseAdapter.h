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

/**
 *  The current country code. Must not be nil.
 *
 *  @return A 2 letter country code
 */
- (NSString *)countryCode;

- (void)adapterWasClicked:(HZBaseAdapter *)adapter;
- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter;

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter;
- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter;

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter;
- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter;

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

@property (nonatomic, strong) NSDictionary *credentials;

@property (nonatomic, strong) HZAdapterDelegate *forwardingDelegate;

+ (instancetype)sharedInstance;

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag;

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag;

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

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials;

#pragma mark - Banners

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate;
- (BOOL)hasBannerCredentials;

#pragma mark - Inferred methods

- (NSString *)sdkVersion;

- (NSString *)name;

- (BOOL)supportsAdType:(HZAdType)adType;

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

@end
