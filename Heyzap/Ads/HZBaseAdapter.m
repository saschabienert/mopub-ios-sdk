//
//  HZBaseAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZBaseAdapter.h"
#import "HZVungleAdapter.h"
#import "HZChartboostAdapter.h"
#import "HZMediationConstants.h"
#import "HZAdColonyAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZHeyzapAdapter.h"
#import "HZAppLovinAdapter.h"
#import "HZUnityAdsAdapter.h"
#import "HZCrossPromoAdapter.h"
#import "HZFacebookAdapter.h"
#import "HZiAdAdapter.h"

@implementation HZBaseAdapter

#define ABSTRACT_METHOD_ERROR() @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Subclasses should override this method" userInfo:nil];

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    ABSTRACT_METHOD_ERROR();
}

#pragma mark - Adapter Protocol

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    ABSTRACT_METHOD_ERROR();
}

+ (BOOL)isSDKAvailable
{
    ABSTRACT_METHOD_ERROR();
}

+ (NSString *)name
{
    ABSTRACT_METHOD_ERROR();
}


+ (NSString *)humanizedName {
    ABSTRACT_METHOD_ERROR();
}

+ (NSString *)sdkVersion
{
    ABSTRACT_METHOD_ERROR();
}

- (HZAdType)supportedAdFormats
{
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)isVideoOnlyNetwork
{
    // Return true for video-only networks like Vungle, whose interstitial support is faked via videos.
    ABSTRACT_METHOD_ERROR();
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    ABSTRACT_METHOD_ERROR();
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    ABSTRACT_METHOD_ERROR();
}

#pragma mark - Inferred methods

- (NSString *)sdkVersion
{
    return [[self class] sdkVersion];
}

- (NSString *)name
{
    return [[self class] name];
}

- (BOOL)supportsAdType:(HZAdType)adType
{
    return [self supportedAdFormats] & adType;
}

- (NSError *)lastErrorForAdType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            return self.lastInterstitialError;
            break;
        }
        case HZAdTypeIncentivized: {
            return self.lastIncentivizedError;
            break;
        }
        case HZAdTypeVideo: {
            return self.lastVideoError;
            break;
        }
    }
}

- (void)clearErrorForAdType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            self.lastInterstitialError = nil;
            break;
        }
        case HZAdTypeIncentivized: {
            self.lastIncentivizedError = nil;
            break;
        }
        case HZAdTypeVideo: {
            self.lastVideoError = nil;
            break;
        }
    }
}

#pragma mark - Implemented Methods

+ (Class)adapterClassForName:(NSString *)adapterName
{
    if ([adapterName isEqualToString:kHZAdapterVungle]) {
        return [HZVungleAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterChartboost]) {
        return [HZChartboostAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterAdColony]) {
        return [HZAdColonyAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterAdMob]) {
        return [HZAdMobAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterHeyzap]) {
        return [HZHeyzapAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterAppLovin]) {
        return [HZAppLovinAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterCrossPromo]) {
        return [HZCrossPromoAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterUnityAds]) {
        return [HZUnityAdsAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterFacebook]) {
        return [HZFacebookAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapteriAd]) {
        return [HZiAdAdapter class];
    } else {
        return nil;
    }
}

+ (NSSet *)allAdapterClasses
{
    return [NSSet setWithObjects:
            [HZVungleAdapter class],
            [HZChartboostAdapter class],
            [HZAdColonyAdapter class],
            [HZAdMobAdapter class],
            [HZHeyzapAdapter class],
            [HZAppLovinAdapter class],
            [HZCrossPromoAdapter class],
            [HZUnityAdsAdapter class],
            [HZCrossPromoAdapter class],
            [HZFacebookAdapter class],
            [HZiAdAdapter class],
            nil];
}

+ (BOOL)isHeyzapAdapter {
    return NO;
}

@end
