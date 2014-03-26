//
//  HZAdColonyProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdColonyProxy.h"
#import "HZAdColony.h"
#import "MediationConstants.h"

@interface HZAdColonyProxy() <HZAdColonyDelegate>

@property (nonatomic, strong) NSString *zoneID;

@end

@implementation HZAdColonyProxy

+ (instancetype)sharedInstance
{
    static HZAdColonyProxy *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZAdColonyProxy alloc] init];
    });
    return proxy;
}

- (void)setupAdColonyWithAppID:(NSString *)appID zoneID:(NSString *)zoneID
{
    NSParameterAssert(appID);
    NSParameterAssert(zoneID);
    self.zoneID = zoneID;
    [HZAdColony configureWithAppID:appID zoneIDs:@[zoneID] delegate:self logging:NO];
}

- (NSString *)zoneID
{
    NSAssert(_zoneID != nil, @"Ad Colony must be initialized with a zone ID");
    return _zoneID;
}

- (BOOL)hasAd
{
    BOOL hasAd = [HZAdColony zoneStatusForZone:self.zoneID] == HZ_ADCOLONY_ZONE_STATUS_ACTIVE;
    NSLog(@"Adcolony has ad = %i",hasAd);
    return hasAd;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-property-ivar"
- (NSError *)lastError
{
    if ([HZAdColony zoneStatusForZone:self.zoneID] == HZ_ADCOLONY_ZONE_STATUS_OFF
        || [HZAdColony zoneStatusForZone:self.zoneID] == HZ_ADCOLONY_ZONE_STATUS_NO_ZONE) {
        return [NSError errorWithDomain:kHZMediatorNameKey code:1 userInfo:@{kHZMediatorNameKey: @"AdColony"}];
    } else {
        return nil;
    }
}
#pragma clang diagnostic pop

- (void)prefetch
{
    // AdColony auto-prefetches
}

- (void)showAd
{
    [HZAdColony playVideoAdForZone:self.zoneID withDelegate:nil];
}

@end
