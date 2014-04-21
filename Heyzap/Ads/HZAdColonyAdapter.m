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

#import <UIKit/UIKit.h>

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
    return HZAdTypeVideo | HZAdTypeIncentivized;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (![[[UIApplication sharedApplication] keyWindow] rootViewController]) {
        NSLog(@"AdColony reqires a root view controller on the keyWindow to show ads. Make sure [[[UIApplication sharedApplication] keyWindow] rootViewController] does not return `nil`.");
        return NO;
    }
    switch (type) {
        case HZAdTypeInterstitial: {
            return NO;
            break;
        }
        case HZAdTypeIncentivized: {
            return [HZAdColony isVirtualCurrencyRewardAvailableForZone:self.incentivizedZoneID];
            break;
        }
        case HZAdTypeVideo: {
            return [HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_ACTIVE;
            break;
        }
    }
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // AdColony auto-prefetches
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    [self.delegate adapterWillPlayAudio:self];
    if (type == HZAdTypeIncentivized) {
        [HZAdColony playVideoAdForZone:self.incentivizedZoneID
                          withDelegate:self
                      withV4VCPrePopup:NO
                      andV4VCPostPopup:NO];
    } else {
        [HZAdColony playVideoAdForZone:self.interstitialZoneID withDelegate:self];
    }
}

- (NSError *)lastErrorForAdType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            if ([HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_OFF
                || [HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_NO_ZONE) {
                return [NSError errorWithDomain:kHZMediatorNameKey code:1 userInfo:@{kHZMediatorNameKey: @"AdColony"}];
            } else {
                return nil;
            }
            break;
        }
        case HZAdTypeIncentivized: {
            if ([HZAdColony zoneStatusForZone:self.incentivizedZoneID] == HZ_ADCOLONY_ZONE_STATUS_OFF
                || [HZAdColony zoneStatusForZone:self.incentivizedZoneID] == HZ_ADCOLONY_ZONE_STATUS_NO_ZONE) {
                return [NSError errorWithDomain:kHZMediatorNameKey code:1 userInfo:@{kHZMediatorNameKey: @"AdColony"}];
            } else {
                return nil;
            }
            break;
        }
        case HZAdTypeVideo: {
            return nil;
            break;
        }
    }
}

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
    if ([zoneID isEqualToString:self.incentivizedZoneID]) {
        if (shown) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
}

@end
