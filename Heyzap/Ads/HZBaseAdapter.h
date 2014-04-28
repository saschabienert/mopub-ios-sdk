//
//  HZBaseAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

// This is a bitmasked parameter, but with the exception of the `supportedAdFormats` method, almost everything else should treat it as just an enum.
typedef NS_OPTIONS(NSUInteger, HZAdType) {
    HZAdTypeInterstitial = 1 << 0,
    HZAdTypeVideo = 1 << 1,
    HZAdTypeIncentivized = 1 << 2,
};

@class HZBaseAdapter;

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


+ (instancetype)sharedInstance;

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag;

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag;

/**
 *  The adapter should show an ad for the given ad type.
 *
 *  @param type The type of ad (video, incentivized, interstitial) to show
 *  @param tag  The tag to show for. All adapters except Heyzap should ignore the tag.
 */
- (void)showAdForType:(HZAdType)type tag:(NSString *)tag;

- (HZAdType)supportedAdFormats;

+ (NSString *)name;

+ (BOOL)isSDKAvailable;

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials;

#pragma mark - Inferred methods

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

@end
