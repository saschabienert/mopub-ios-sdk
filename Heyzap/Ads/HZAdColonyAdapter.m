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

@property (nonatomic, strong) NSDate *initializedAt;

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

- (BOOL) hasNecessaryCredentials {
    return self.appID != nil;
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

- (NSString *)testActivityInstructions {
    return @"If you have trouble receiving AdColony ads, try setting \"Show test ads only\" to \"Yes\" for each zone on your AdColony dashboard.";
}

- (void) toggleLogging { HZDLog(@"Logs for %@ can only be enabled/disabled before initialization.", [[self class] humanizedName]); }

- (NSError *)internalInitializeSDK {
    RETURN_ERROR_UNLESS([self hasNecessaryCredentials], ([NSString stringWithFormat:@"%@ needs an App ID set up on your dashboard.", [self humanizedName]]));
    
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
    self.initializedAt = [NSDate date];
    return nil;
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeVideo | HZCreativeTypeIncentivized;
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    if (![[[UIApplication sharedApplication] keyWindow] rootViewController]) {
        HZAlwaysLog(@"AdColony reqires a root view controller on the keyWindow to show ads. Make sure [[[UIApplication sharedApplication] keyWindow] rootViewController] does not return `nil`.");
        return NO;
    }
    switch (dataProvider.creativeType) {
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

- (void)internalPrefetchAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    // AdColony auto-prefetches
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options
{
    if (options.creativeType == HZCreativeTypeIncentivized) {
        [self.delegate adapterWillPlayAudio:self];
        [HZAdColony playVideoAdForZone:self.incentivizedZoneID
                          withDelegate:self
                      withV4VCPrePopup:NO
                      andV4VCPostPopup:NO];
    } else if(options.creativeType == HZCreativeTypeVideo){
        [self.delegate adapterWillPlayAudio:self];
        [HZAdColony playVideoAdForZone:self.interstitialZoneID withDelegate:self];
    }
}

#pragma mark - Errors

- (NSString *)errorDescriptionForZoneStatus:(HZ_ADCOLONY_ZONE_STATUS)zoneStatus {
    switch (zoneStatus) {
        case HZ_ADCOLONY_ZONE_STATUS_OFF: {
            return @"This zone ID is invalid or turned off on the AdColony dashboard.";
        }
        case HZ_ADCOLONY_ZONE_STATUS_NO_ZONE: {
            return @"AdColony has not been configured with this zone ID.";
        }
        case HZ_ADCOLONY_ZONE_STATUS_UNKNOWN: {
            return @"AdColony has not yet received this zone's configuration from the server. This can occur just after their SDK is initialized, before an ad has finished loading, or if there is no fill available. If you enable third party logging ([HZLog setThirdPartyLoggingEnabled:YES];) before starting the Heyzap SDK, AdColony will log that \"There is currently no fill for zone <zoneID>\" if there is no fill. For testing purposes, you can try setting \"Show test ads only\" to \"Yes\" for this zone on the AdColony dashboard if this is the case.";
        }
        case HZ_ADCOLONY_ZONE_STATUS_LOADING:
        case HZ_ADCOLONY_ZONE_STATUS_ACTIVE: {
            return nil;
        }
    }
}

const NSTimeInterval kHZAdColonyInitializationToFetchInterval = 7.0;
- (NSError *)lastFetchErrorForAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    static BOOL didLogInitializationIntervalMessage = NO;
    
    NSString *const zone = [self zoneIDForCreativeType:dataProvider.creativeType];
    if (zone) {
        HZ_ADCOLONY_ZONE_STATUS status = [HZAdColony zoneStatusForZone:zone];
        
        // AdColony's zones are HZ_ADCOLONY_ZONE_STATUS_UNKNOWN when fetching just after initializing the SDK as it waits for its initial network requests.
        // On strong wifi they needed up to 6 seconds between init and fetch to succeed when I tested this.
        // Don't report the HZ_ADCOLONY_ZONE_STATUS_UNKNOWN error during a short window after initialization to give it a chance to fetch.
        if (status == HZ_ADCOLONY_ZONE_STATUS_UNKNOWN && [[NSDate date] timeIntervalSinceDate:self.initializedAt] < kHZAdColonyInitializationToFetchInterval) {
            if (!didLogInitializationIntervalMessage) {
                HZDLog(@"AdColony was initialized within the last %i seconds, and is being given time to initialize and fetch before erroring out.", (int)kHZAdColonyInitializationToFetchInterval);
                didLogInitializationIntervalMessage = YES;
            }
            
            return nil;
        }
        
        NSString *const errorDescription = [self errorDescriptionForZoneStatus:status];
        if (errorDescription) {
            return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:
                        @{kHZMediatorNameKey: [self humanizedName],
                          @"AdColonyZoneID":zone,
                          NSLocalizedDescriptionKey:errorDescription,
                          }];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

// unimplemented, we retrieve errors directly from the AdColony SDK. overridden here just to note this as intentional
- (void) setLastFetchError:(NSError *)error forAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {}
- (void) clearLastFetchErrorForAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {}

#pragma mark - Util

- (NSString *)zoneIDForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeVideo: {
            return self.interstitialZoneID;
        }
        case HZCreativeTypeIncentivized: {
            return self.incentivizedZoneID;
        }
        case HZCreativeTypeNative:
        case HZCreativeTypeBanner:
        case HZCreativeTypeStatic:
        case HZCreativeTypeUnknown: {
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
