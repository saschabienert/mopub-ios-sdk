//
//  MediationConstants.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

@interface HZMediationConstants : NSObject

/**
 *  Generic NSError domain
 */
extern NSString * const kHZMediationDomain;

/**
 *  NSErrors for credentials
 */
extern NSString * const kHZMediationCredentialsDomain;

/**
 *  NSError userInfo key.
 */
extern NSString * const kHZMediatorNameKey;

// Known mediators
extern NSString * const kHZAdapterVungle;
extern NSString * const kHZAdapterChartboost;
extern NSString * const kHZAdapterAdColony;
extern NSString * const kHZAdapterAdMob;
extern NSString * const kHZAdapterHeyzap;
extern NSString * const kHZAdapterCrossPromo;
extern NSString * const kHZAdapterAppLovin;
extern NSString * const kHZAdapterUnityAds;

// Humanized names for known mediators
extern NSString * const kHZAdapterVungleHumanized;
extern NSString * const kHZAdapterChartboostHumanized;
extern NSString * const kHZAdapterAdColonyHumanized;
extern NSString * const kHZAdapterAdMobHumanized;
extern NSString * const kHZAdapterHeyzapHumanized;
extern NSString * const kHZAdapterCrossPromoHumanized;
extern NSString * const kHZAdapterAppLovinHumanized;
extern NSString * const kHZAdapterUnityAdsHumanized;

+ (NSError *)errorWithAdapter:(NSString *)adapter
                       domain:(NSString *)domain
                     userInfo:(NSDictionary *)userInfo;

+ (NSError *)credentialErrorForAdapter:(Class)adapter error:(NSError *)error;

// Must be used from a class method of an adapter, presumably `enableWithCredentials:`
#define CHECK_CREDENTIALS_ERROR(error) if (error) { return [HZMediationConstants credentialErrorForAdapter:self error:error]; }

NSString * NSStringFromAdType(HZAdType type);
HZAdType hzAdTypeFromString(NSString *adUnit);
+ (NSArray *)creativeTypesForAdType:(HZAdType)type;

@end
