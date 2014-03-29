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

+ (NSError *)credentialErrorForAdapter:(Class<HZMediationAdapter>)adapter error:(NSError *)error
{
    return [HZMediationConstants errorWithAdapter:[adapter name]
                                           domain:kHZMediationCredentialsDomain
                                         userInfo:error.userInfo];
}

@end
