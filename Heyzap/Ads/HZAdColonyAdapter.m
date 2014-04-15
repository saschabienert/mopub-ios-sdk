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

@property (nonatomic, strong) NSString *interstitialZoneID;
@property (nonatomic, strong) NSString *incentivizedZoneID;

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
    
    NSString *const interstitialZoneID = [HZDictionaryUtils objectForKey:@"interstitial_zone_id"
                                                     ofClass:[NSString class]
                                                        dict:credentials
                                                       error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *const incentivizedZoneID = [HZDictionaryUtils objectForKey:@"incentivized_zone_id"
                                                                 ofClass:[NSString class]
                                                                    dict:credentials
                                                                   error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    
    [[self sharedInstance] setupAdColonyWithAppID:appID
                               interstitialZoneID:interstitialZoneID
                               incentivizedZoneID:incentivizedZoneID];
    
    return nil;
}

- (void)setupAdColonyWithAppID:(NSString *)appID
            interstitialZoneID:(NSString *)interstitialZoneID
            incentivizedZoneID:(NSString *)incentivizedZoneID
{
    NSParameterAssert(appID);
    NSParameterAssert(interstitialZoneID);
    NSParameterAssert(incentivizedZoneID);
    self.interstitialZoneID = interstitialZoneID;
    self.incentivizedZoneID = incentivizedZoneID;
    [HZAdColony configureWithAppID:appID
                           zoneIDs:@[interstitialZoneID,incentivizedZoneID]
                          delegate:self
                           logging:NO];
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeVideo;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    return (type & [self supportedAdFormats]) && [HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_ACTIVE;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // AdColony auto-prefetches
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    [HZAdColony playVideoAdForZone:self.interstitialZoneID withDelegate:self];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-property-ivar"
- (NSError *)lastError
{
    if ([HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_OFF
        || [HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_NO_ZONE) {
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
