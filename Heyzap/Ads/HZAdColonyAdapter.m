//
//  HZAdColonyProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdColonyAdapter.h"
#import "HZAdColony.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"

@interface HZAdColonyAdapter() <HZAdColonyDelegate, HZAdColonyAdDelegate>

@property (nonatomic, strong) NSString *zoneID;

@end

@implementation HZAdColonyAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZAdColonyAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZAdColonyAdapter alloc] init];
    });
    return proxy;
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable
{
    return [HZAdColony hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return kHZAdapterAdColony;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    NSParameterAssert(credentials);
    NSError *error;
    NSString *appID = [HZDictionaryUtils objectForKey:@"app_id"
                                              ofClass:[NSString class]
                                                 dict:credentials
                                                error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *const zoneID = [HZDictionaryUtils objectForKey:@"zone_id"
                                                     ofClass:[NSString class]
                                                        dict:credentials
                                                       error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    [[self sharedInstance] setupAdColonyWithAppID:appID zoneID:zoneID];
    
    return nil;
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

- (HZAdType)supportedAdFormats
{
    return HZAdTypeVideo;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    return (type & [self supportedAdFormats]) && [HZAdColony zoneStatusForZone:self.zoneID] == HZ_ADCOLONY_ZONE_STATUS_ACTIVE;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // AdColony auto-prefetches
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    [HZAdColony playVideoAdForZone:self.zoneID withDelegate:self];
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

#pragma mark - AdColony Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"AdColonyAdDelegate"]) {
        return YES;
    } else if ([NSStringFromProtocol(aProtocol) isEqualToString:@"AdColonyDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

#pragma mark - AdColonyAdDelegate (individual ads)

- (void)onAdColonyAdAttemptFinished:(BOOL)shown inZone:(NSString *)zoneID
{
    [self.delegate adapterDidDismissAd:self];
}

@end
