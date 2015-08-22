//
//  MediationConstants.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"
#import "HZCreativeType.h"
#import "HZAdType.h"

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
extern NSString * const kHZAdapterLeadboltHumanized;

+ (NSError *)errorWithAdapter:(NSString *)adapter
                       domain:(NSString *)domain
                     userInfo:(NSDictionary *)userInfo;

#define RETURN_ERROR_IF_NIL(value,name) do { \
if (value == nil) { \
return [NSError errorWithDomain:kHZMediationDomain code:3 userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"Missing value: %@",name]}]; \
} \
} while (0)

+ (NSArray *)legacyCreativeTypesForAdType:(HZAdType)type;

BOOL hzCreativeTypeStringSetContainsAdType(NSSet *const creativeTypes, const HZAdType adType);
NSSet * hzCreativeTypesPossibleForAdType(HZAdType adType);
@end
