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
#import "HZBaseAdapter_Internal.h"

#import <UIKit/UIKit.h>

@interface HZAdColonyAdapter() <HZAdColonyDelegate, HZAdColonyAdDelegate>

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *interstitialZoneID;
@property (nonatomic, strong) NSString *incentivizedZoneID;

@end

@implementation HZAdColonyAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
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

- (void) toggleLogging { HZDLog(@"Logs for %@ can only be enabled/disabled before initialization.", [[self class] humanizedName]); }

- (NSError *)internalInitializeSDK {
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
                           logging:[self isLoggingEnabled]];
    return nil;
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeVideo | HZCreativeTypeIncentivized;
}

- (BOOL)internalHasAdForCreativeType:(HZCreativeType)creativeType
{
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

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeIncentivized: {
            return self.incentivizedZoneID != nil;
        }
        case HZCreativeTypeVideo: {
            return self.interstitialZoneID != nil;
        }
        default:
            return NO;
    }
}

- (void)internalPrefetchForCreativeType:(HZCreativeType)creativeType
{
    // AdColony auto-prefetches
}

- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
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

- (NSError *)lastFetchErrorForCreativeType:(HZCreativeType)creativeType
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
