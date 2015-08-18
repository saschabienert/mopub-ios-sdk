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

@property (nonatomic, strong) NSString *appID;
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

- (void)loadCredentials {
    self.appID = [HZDictionaryUtils objectForKey:@"app_id"
                                         ofClass:[NSString class]
                                            dict:self.credentials];
    
    self.interstitialZoneID = [HZDictionaryUtils objectForKey:@"interstitial_zone_id"
                                                      ofClass:[NSString class]
                                                         dict:self.credentials];
    
    self.incentivizedZoneID = [HZDictionaryUtils objectForKey:@"incentivized_zone_id"
                                                      ofClass:[NSString class]
                                                         dict:self.credentials];
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

- (NSError *)initializeSDK {
    RETURN_ERROR_IF_NIL(self.appID, @"app_id");
    
    NSArray *const zoneIDs = ({
        NSMutableArray *ids = [NSMutableArray array];
        
        if (self.interstitialZoneID) { [ids addObject:self.interstitialZoneID]; }
        if (self.incentivizedZoneID) { [ids addObject:self.incentivizedZoneID]; }
        
        ids;
    });
    
    HZDLog(@"Initializing AdColony with App ID: %@ and zoneIDs: %@",self.appID, zoneIDs);
    [HZAdColony configureWithAppID:self.appID
                           zoneIDs:zoneIDs
                          delegate:self.forwardingDelegate
                           logging:NO];
    return nil;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return YES;
}

- (BOOL)hasAdForType:(HZAdType)type
{
    if (![[[UIApplication sharedApplication] keyWindow] rootViewController]) {
        // This is important so we should always NSLog this.
        NSLog(@"AdColony reqires a root view controller on the keyWindow to show ads. Make sure [[[UIApplication sharedApplication] keyWindow] rootViewController] does not return `nil`.");
        return NO;
    }
    switch (type) {
        case HZAdTypeIncentivized: {
            return [HZAdColony isVirtualCurrencyRewardAvailableForZone:self.incentivizedZoneID];
            break;
        }
        case HZAdTypeInterstitial:
        case HZAdTypeVideo: {
            return [HZAdColony zoneStatusForZone:self.interstitialZoneID] == HZ_ADCOLONY_ZONE_STATUS_ACTIVE;
            break;
        }
        case HZAdTypeBanner: {
            return NO;
        }
    }
}

- (BOOL)hasCredentialsForAdType:(HZAdType)adType {
    switch (adType) {
        case HZAdTypeIncentivized: {
            return self.incentivizedZoneID != nil;
        }
        case HZAdTypeInterstitial:
        case HZAdTypeVideo: {
            return self.interstitialZoneID != nil;
        }
        case HZAdTypeBanner: {
            return NO;
        }
    }
}

- (void)prefetchForType:(HZAdType)type
{
    // AdColony auto-prefetches
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
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
        case HZAdTypeVideo:
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
        case HZAdTypeBanner: {
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
