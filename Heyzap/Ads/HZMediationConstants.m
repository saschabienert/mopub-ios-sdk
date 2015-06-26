//
//  MediationConstants.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"

@implementation HZMediationConstants

NSString * const kHZMediationDomain = @"HeyzapMediation";
NSString * const kHZMediationCredentialsDomain = @"HeyzapMediationCredentials";
NSString * const kHZMediatorNameKey = @"MediatorName";

// Humanized names for known mediators
NSString * const kHZAdapterVungleHumanized = @"Vungle";
NSString * const kHZAdapterChartboostHumanized = @"Chartboost";
NSString * const kHZAdapterAdColonyHumanized = @"AdColony";
NSString * const kHZAdapterAdMobHumanized = @"AdMob";
NSString * const kHZAdapterHeyzapHumanized = @"Heyzap";
NSString * const kHZAdapterCrossPromoHumanized = @"Heyzap Cross Promotion";
NSString * const kHZAdapterAppLovinHumanized = @"AppLovin";
NSString * const kHZAdapterUnityAdsHumanized = @"UnityAds";
NSString * const kHZAdapterFacebookHumanized = @"Facebook Audience Network";
NSString * const kHZAdapteriAdHumanized = @"iAd";

#define HZInterstitialAdCreativeTypes @[@"interstitial", @"full_screen_interstitial", @"video", @"interstitial_video"]
#define HZIncentivizedAdCreativeTypes @[@"video", @"interstitial_video"]
#define HZVideoAdCreativeTypes @[@"video", @"interstitial_video"]
#define HZBannerAdCreativeTypes @[@"banner"]

+ (NSError *)errorWithAdapter:(NSString *)adapter
                       domain:(NSString *)domain
                     userInfo:(NSDictionary *)userInfo
{
    HZParameterAssert(adapter);
    HZParameterAssert(domain);
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    errorInfo[kHZMediatorNameKey] = adapter;
    return [NSError errorWithDomain:domain code:1 userInfo:errorInfo];
}

+ (NSError *)credentialErrorForAdapter:(Class)adapter error:(NSError *)error
{
    return [HZMediationConstants errorWithAdapter:[adapter name]
                                           domain:kHZMediationCredentialsDomain
                                         userInfo:error.userInfo];
}

NSString * NSStringFromAdType(HZAdType type)
{
    switch (type) {
        case HZAdTypeInterstitial: {
            return @"interstitial";
            break;
        }
        case HZAdTypeIncentivized: {
            return @"incentivized";
            break;
        }
        case HZAdTypeVideo: {
            return @"video";
            break;
        }
        case HZAdTypeBanner: {
            return @"banner";
        }
    }
}

HZAdType hzAdTypeFromString(NSString *adUnit) {
    if ([adUnit isEqualToString:@"incentivized"]) {
        return HZAdTypeIncentivized;
    } else if ([adUnit isEqualToString:@"video"]) {
        return HZAdTypeVideo;
    } else {
        return HZAdTypeInterstitial;
    }
}

+ (NSArray *)creativeTypesForAdType:(HZAdType)type
{
    switch (type) {
        case HZAdTypeIncentivized: {
            return HZIncentivizedAdCreativeTypes;
            break;
        }
        case HZAdTypeInterstitial: {
            return HZInterstitialAdCreativeTypes;
            break;
        }
        case HZAdTypeVideo: {
            return HZVideoAdCreativeTypes;
            break;
        }
        case HZAdTypeBanner: {
            return HZBannerAdCreativeTypes;
        }
    }
}

NSString * const hzCreativeTypeIncentivized = @"INCENTIVIZED";
NSString * const hzCreativeTypeVideo = @"VIDEO";
NSString * const hzCreativeTypeBanner = @"BANNER";
NSString * const hzCreativeTypeInterstitial = @"STATIC";



HZAdType hzAdTypeFromCreativeTypeString(NSString *adUnit) {
    if ([adUnit isEqualToString:@"INCENTIVIZED"]) {
        return HZAdTypeIncentivized;
    } else if ([adUnit isEqualToString:@"VIDEO"]) {
        return HZAdTypeVideo;
    } else if ([adUnit isEqualToString:@"BANNER"]) {
        return HZAdTypeBanner;
    } else {
        return HZAdTypeInterstitial;
    }
}

BOOL hzCreativeTypeSetContainsAdType(NSSet *const creativeTypes, const HZAdType adType) {
    switch (adType) {
        case HZAdTypeIncentivized: {
            return [creativeTypes containsObject:hzCreativeTypeIncentivized];
            break;
        }
        case HZAdTypeVideo: {
            return [creativeTypes containsObject:hzCreativeTypeVideo];
            break;
        }
        case HZAdTypeBanner: {
            return [creativeTypes containsObject:hzCreativeTypeBanner];
            break;
        }
        case HZAdTypeInterstitial: {
            return [creativeTypes containsObject:hzCreativeTypeInterstitial];
            break;
        }
    }
}

@end
