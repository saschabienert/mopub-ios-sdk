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
extern NSString * const kHZAdapterInMobiHumanized;

+ (NSError *)errorWithAdapter:(NSString *)adapter
                       domain:(NSString *)domain
                     userInfo:(NSDictionary *)userInfo;

#define RETURN_ERROR_UNLESS(value,error_msg) do { \
if (value == NO) { \
return [NSError errorWithDomain:kHZMediationDomain code:3 userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"%@",error_msg]}]; \
} \
} while (0)

NSMutableSet<HZCreativeTypeObject *> * hzCreativeTypesPossibleForAdType(HZAdType adType);
@end
