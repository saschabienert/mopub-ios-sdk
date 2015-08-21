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
#import "HeyzapAds.h"
#import "HeyzapMediation.h"

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
        proxy.forwardingDelegate = [HZAdapterDelegate new];
        proxy.forwardingDelegate.adapter = proxy;
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
    return HZNetworkAdColony;
}

+ (NSString *)humanizedName
{
    return kHZAdapterAdColonyHumanized;
}

+ (NSString *)sdkVersion {
    return nil; // AdColony doesn't provide the SDK version

}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    HZParameterAssert(credentials);
    NSError *error;
    NSString *appID = [HZDictionaryUtils objectForKey:@"app_id"
                                              ofClass:[NSString class]
                                                 dict:credentials
                                                error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *interstitialZoneID = [HZDictionaryUtils objectForKey:@"interstitial_zone_id"
                                                     ofClass:[NSString class]
                                                        dict:credentials
                                                       error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *incentivizedZoneID = [HZDictionaryUtils objectForKey:@"incentivized_zone_id"
                                                                 ofClass:[NSString class]
                                                                    dict:credentials
                                                                   error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    HZAdColonyAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        [[self sharedInstance] setupAdColonyWithAppID:appID
                                   interstitialZoneID:interstitialZoneID
                                   incentivizedZoneID:incentivizedZoneID];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    }
    
    return nil;
}

- (void)setupAdColonyWithAppID:(NSString *)appID
            interstitialZoneID:(NSString *)interstitialZoneID
            incentivizedZoneID:(NSString *)incentivizedZoneID
{
    HZParameterAssert(appID);
    HZParameterAssert(interstitialZoneID);
    HZParameterAssert(incentivizedZoneID);
    self.interstitialZoneID = interstitialZoneID;
    self.incentivizedZoneID = incentivizedZoneID;
    [HZAdColony configureWithAppID:appID
                           zoneIDs:@[interstitialZoneID,incentivizedZoneID]
                          delegate:self.forwardingDelegate
                           logging:NO];
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeVideo | HZCreativeTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return YES;
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    if(![self supportsCreativeType:creativeType]) return NO;
    
    if (![[[UIApplication sharedApplication] keyWindow] rootViewController]) {
        // This is important so we should always NSLog this.
        NSLog(@"AdColony reqires a root view controller on the keyWindow to show ads. Make sure [[[UIApplication sharedApplication] keyWindow] rootViewController] does not return `nil`.");
        return NO;
    }
    switch (creativeType) {
        case HZCreativeTypeIncentivized: {
            return [HZAdColony isVirtualCurrencyRewardAvailableForZone:self.incentivizedZoneID];
            break;
        }
        case HZCreativeTypeVideo: {
            return [HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_ACTIVE;
            break;
        }
        default: {
            return NO;
        }
    }
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    // AdColony auto-prefetches
}

- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    if(![self supportsCreativeType:creativeType]) return;
    
    if (creativeType == HZCreativeTypeIncentivized) {
        [self.delegate adapterWillPlayAudio:self];
        [HZAdColony playVideoAdForZone:self.incentivizedZoneID
                          withDelegate:self
                      withV4VCPrePopup:NO
                      andV4VCPostPopup:NO];
    } else if(creativeType == HZCreativeTypeVideo){
        [self.delegate adapterWillPlayAudio:self];
        [HZAdColony playVideoAdForZone:self.interstitialZoneID withDelegate:self];
    }
}

- (NSError *)lastErrorForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeVideo: {
            if ([HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_OFF
                || [HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_NO_ZONE) {
                return [NSError errorWithDomain:kHZMediatorNameKey code:1 userInfo:@{kHZMediatorNameKey: @"AdColony"}];
            } else {
                return nil;
            }
            break;
        }
        case HZCreativeTypeIncentivized: {
            if ([HZAdColony zoneStatusForZone:self.incentivizedZoneID] == HZ_ADCOLONY_ZONE_STATUS_OFF
                || [HZAdColony zoneStatusForZone:self.incentivizedZoneID] == HZ_ADCOLONY_ZONE_STATUS_NO_ZONE) {
                return [NSError errorWithDomain:kHZMediatorNameKey code:1 userInfo:@{kHZMediatorNameKey: @"AdColony"}];
            } else {
                return nil;
            }
            break;
        }
        default: {
            return nil;
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

- ( void ) onAdColonyAdStartedInZone:( NSString * )zoneID {
    [self.delegate adapterDidShowAd:self];
}

- (void)onAdColonyAdAttemptFinished:(BOOL)shown inZone:(NSString *)zoneID
{
    if ([zoneID isEqualToString:self.incentivizedZoneID]) {
        if (shown) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
            
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
    // unfortunately, adcolony doesn't tell us whether the ad was clicked or dismissed
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
}

@end
