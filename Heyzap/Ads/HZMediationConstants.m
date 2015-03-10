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

// Known mediators
NSString * const kHZAdapterVungle = @"vungle";
NSString * const kHZAdapterChartboost = @"chartboost";
NSString * const kHZAdapterAdColony = @"adcolony";
NSString * const kHZAdapterAdMob = @"admob";
NSString * const kHZAdapterHeyzap = @"heyzap";
NSString * const kHZAdapterCrossPromo = @"heyzap_cross_promo";
NSString * const kHZAdapterAppLovin = @"applovin";
NSString * const kHZAdapterUnityAds = @"unityads";
NSString * const kHZAdapterFacebook = @"facebook";
NSString * const kHZAdapteriAd = @"iad";

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

+ (NSError *)errorWithAdapter:(NSString *)adapter
                       domain:(NSString *)domain
                     userInfo:(NSDictionary *)userInfo
{
    NSParameterAssert(adapter);
    NSParameterAssert(domain);
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
    }
}

@end
