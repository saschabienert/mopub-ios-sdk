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
NSString * const kHZAdapterHeyzapExchangeHumanized = @"Heyzap Exchange";
NSString * const kHZAdapterLeadboltHumanized = @"Leadbolt";
NSString * const kHZAdapterInMobiHumanized = @"InMobi";

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

#pragma mark - Converting from HZAdType to HZCreativeType

NSMutableSet<HZCreativeTypeObject *> * hzCreativeTypesPossibleForAdType(HZAdType adType) {
    switch(adType){
        case HZAdTypeInterstitial:
            return [NSMutableSet setWithArray:@[@(HZCreativeTypeVideo), @(HZCreativeTypeStatic)]];
        case HZAdTypeIncentivized:
            return [NSMutableSet setWithArray:@[@(HZCreativeTypeIncentivized)]];
        case HZAdTypeBanner:
            return [NSMutableSet setWithArray:@[@(HZCreativeTypeBanner)]];
        case HZAdTypeVideo:
            return [NSMutableSet setWithArray:@[@(HZCreativeTypeVideo)]];
        case HZAdTypeNative:
            return [NSMutableSet setWithArray:@[@(HZCreativeTypeNative)]];
    }
}

@end
