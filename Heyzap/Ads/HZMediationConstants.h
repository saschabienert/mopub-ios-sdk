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

// Humanized names for known mediators
extern NSString * const kHZAdapterVungleHumanized;
extern NSString * const kHZAdapterChartboostHumanized;
extern NSString * const kHZAdapterAdColonyHumanized;
extern NSString * const kHZAdapterAdMobHumanized;
extern NSString * const kHZAdapterHeyzapHumanized;
extern NSString * const kHZAdapterCrossPromoHumanized;
extern NSString * const kHZAdapterAppLovinHumanized;
extern NSString * const kHZAdapterUnityAdsHumanized;
extern NSString * const kHZAdapterFacebookHumanized;
extern NSString * const kHZAdapteriAdHumanized;
extern NSString * const kHZAdapterHeyzapExchangeHumanized;

+ (NSError *)errorWithAdapter:(NSString *)adapter
                       domain:(NSString *)domain
                     userInfo:(NSDictionary *)userInfo;

#define RETURN_ERROR_IF_NIL(value,name) do { \
if (value == nil) { \
return [NSError errorWithDomain:kHZMediationDomain code:3 userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"Missing value: %@",name]}]; \
} \
} while (0)

NSString * NSStringFromAdType(HZAdType type);
HZAdType hzAdTypeFromString(NSString *adUnit);
+ (NSArray *)creativeTypesForAdType:(HZAdType)type;

HZAdType hzAdTypeFromCreativeTypeString(NSString *creativeTypeString);

BOOL hzCreativeTypeSetContainsAdType(NSSet *const creativeTypes, const HZAdType adType);

@end
