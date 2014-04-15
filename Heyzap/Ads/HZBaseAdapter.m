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

@implementation HZBaseAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    abort();
}

#pragma mark - Adapter Protocol

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    abort();
}

+ (BOOL)isSDKAvailable
{
    abort();
}

+ (NSString *)name
{
    abort();
}

- (HZAdType)supportedAdFormats
{
    abort();
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    abort();
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    abort();
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    abort();
}

#pragma mark - Inferred methods

- (NSString *)name
{
    return [[self class] name];
}

- (BOOL)supportsAdType:(HZAdType)adType
{
    return [self supportedAdFormats] & adType;
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
            nil];
}

@end
