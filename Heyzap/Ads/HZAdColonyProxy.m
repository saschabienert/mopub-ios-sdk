//
//  HZAdColonyProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdColonyProxy.h"
#import <AdColony/AdColony.h>

@interface HZAdColonyProxy()

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
    [AdColony configureWithAppID:appID zoneIDs:@[zoneID] delegate:nil logging:NO];
}

- (NSString *)zoneID
{
    NSAssert(_zoneID != nil, @"Ad Colony must be initialized with a zone ID");
    return _zoneID;
}

- (BOOL)hasAd
{
    BOOL hasAd = [AdColony zoneStatusForZone:self.zoneID] == ADCOLONY_ZONE_STATUS_ACTIVE;
    NSLog(@"Adcolony has ad = %i",hasAd);
    return hasAd;
}

- (void)prefetch
{
    // AdColony auto-prefetches
}

- (void)showAd
{
    [AdColony playVideoAdForZone:self.zoneID withDelegate:nil];
}

@end
