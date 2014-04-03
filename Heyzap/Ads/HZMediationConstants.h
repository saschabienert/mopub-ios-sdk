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

+ (NSError *)errorWithAdapter:(NSString *)adapter
                       domain:(NSString *)domain
                     userInfo:(NSDictionary *)userInfo;

+ (NSError *)credentialErrorForAdapter:(Class)adapter error:(NSError *)error;

#define CHECK_CREDENTIALS_ERROR(error) if (error) { return [HZMediationConstants credentialErrorForAdapter:self error:error]; }



@end
