//
//  HZAppLovinAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAppLovinAdapter.h"
#import "HZMediationConstants.h"

#import "HZDictionaryUtils.h"
#import "HZAppLovinDelegate.h"

#import "HZALSdk.h"
#import "HZALSdkSettings.h"
#import "HZALInterstitialAd.h"
#import "HZALAdService.h"
#import "HZALAd.h"
#import "HZALIncentivizedInterstitialAd.h"
#import "HZALAdSize.h"
#import "HZIncentivizedAppLovinDelegate.h"

#import "HeyzapMediation.h"
#import "HeyzapAds.h"
#import "HZBaseAdapter_Internal.h"

/**
 *  AppLovin's SDK is split between using (singletons+class methods) vs instances. Inexplicably, the former group is only available when you store the SDK Key in your info.plist file, so we need to use the instance methods.
 */
@interface HZAppLovinAdapter()

@property (nonatomic, strong) NSString *sdkKey;
// (We either need to store the HZALSdk or the sdkKey because the ads take SDK instance as an argument)
@property (nonatomic, strong) HZALSdk *sdk;

@property (nonatomic, strong) NSString *test;

@property (nonatomic, strong) HZALIncentivizedInterstitialAd *currentIncentivizedAd;

@property (nonatomic, strong) HZAppLovinDelegate *interstitialDelegate;
@property (nonatomic, strong) HZIncentivizedAppLovinDelegate *incentivizedDelegate;

@property (nonatomic, strong) NSError *incentivizedError;

@property (nonatomic, strong) HZALInterstitialAd *currentInterstitialAd;

@end

@implementation HZAppLovinAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
{
    static HZAppLovinAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZAppLovinAdapter alloc] init];
        adapter.forwardingDelegate = [HZAdapterDelegate new];
        adapter.forwardingDelegate.adapter = adapter;
    });
    return adapter;
}

- (void)loadCredentials {
    self.sdkKey = [HZDictionaryUtils objectForKey:@"sdk_key" ofClass:[NSString class] dict:self.credentials];
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable
{
    return [HZALSdk hzProxiedClassIsAvailable]
    && [HZALInterstitialAd hzProxiedClassIsAvailable]
    && [HZALAdService hzProxiedClassIsAvailable]
    && [HZALAd hzProxiedClassIsAvailable]
    && [HZALIncentivizedInterstitialAd hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return HZNetworkAppLovin;
}

+ (NSString *)humanizedName
{
    return kHZAdapterAppLovinHumanized;
}

+ (NSString *)sdkVersion {
    return [HZALSdk version];
}

- (void) toggleLogging { HZDLog(@"Logs for %@ can only be enabled/disabled before initialization.", [[self class] humanizedName]); }

- (NSError *)internalInitializeSDK {
    RETURN_ERROR_IF_NIL(self.sdkKey, @"sdk_key");
    
    HZDLog(@"Initializing AppLovin with SDK Key: %@",self.sdkKey);
    HZALSdkSettings *settings = [HZALSdkSettings alloc];
    settings.isVerboseLogging = [self isLoggingEnabled];
    self.sdk = [HZALSdk sharedWithKey:self.sdkKey settings:settings];
    [self.sdk initializeSdk];
    
    return nil;
}

- (HZCreativeType) supportedCreativeTypes
{
    // We don't currently have a way to tell if an interstitial from AppLovin is a static or video ad.
    // Until we do, we will treat them as all static.
    return HZCreativeTypeStatic | HZCreativeTypeIncentivized;
}

// To support incentivized, I will need to have separate objects for the incentivized/interstial delegates because they received the same selectors
- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            [[self.sdk adService] preloadAdOfSize:[HZALAdSize sizeInterstitial]];
            break;
        }
        case HZCreativeTypeIncentivized: {
            if (self.currentIncentivizedAd) {
                return;
            }
            self.currentIncentivizedAd = [[HZALIncentivizedInterstitialAd alloc] initIncentivizedInterstitialWithSdk:self.sdk];
            self.incentivizedDelegate = [[HZIncentivizedAppLovinDelegate alloc] initWithCreativeType:creativeType delegate:self.forwardingDelegate];
            [self.currentIncentivizedAd preloadAndNotify:self.incentivizedDelegate];
            self.currentIncentivizedAd.adVideoPlaybackDelegate = self.incentivizedDelegate;
            
            break;
        }
        case HZCreativeTypeVideo: // not supported right now since AppLovin doesn't differentiate between static and video interstitials
        default: {
            // Not supported
            break;
        }
    }
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            return [[self.sdk adService] hasPreloadedAdOfSize:[HZALAdSize sizeInterstitial]];
            break;
        }
        case HZCreativeTypeIncentivized: {
            return self.currentIncentivizedAd.isReadyForDisplay;
        }
        case HZCreativeTypeVideo:
        default: {
            return NO;
            break;
        }
    }
}

- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    if (creativeType == HZCreativeTypeIncentivized) {
        
        if (self.currentIncentivizedAd && [self.currentIncentivizedAd isReadyForDisplay]) {
            self.currentIncentivizedAd.adDisplayDelegate = self.incentivizedDelegate;
            [self.currentIncentivizedAd showOver:[[UIApplication sharedApplication] keyWindow]
                                       andNotify:self.incentivizedDelegate];
        } else {
            [self appLovinFailedToShowWithUnderlyingError:self.incentivizedError];
        }
    } else if(creativeType == HZCreativeTypeStatic) {
        // We just need to keep a strong reference to the last HZALInterstitialAd to prevent it from being deallocated (this started being required in AppLovin 3.0.2)
        self.currentInterstitialAd = [[HZALInterstitialAd alloc] initInterstitialAdWithSdk:self.sdk];
        self.currentInterstitialAd.adDisplayDelegate = self.interstitialDelegate;
        self.currentInterstitialAd.adVideoPlaybackDelegate = self.interstitialDelegate;
        
        if ([self.currentInterstitialAd isReadyForDisplay]) {
            [self.currentInterstitialAd show];
        } else {
            self.currentInterstitialAd = nil;
            [self appLovinFailedToShowWithUnderlyingError:nil];
        }
    }
}

- (void)appLovinFailedToShowWithUnderlyingError:(NSError *)underlyingError {
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    userInfo[NSLocalizedDescriptionKey] = @"Unable to load ad from AppLovin.";
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] =underlyingError;
    }
    
    [self.delegate adapterDidFailToShowAd:self error:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:userInfo]];
}

#pragma mark - AppLovinDelegateReceiver

- (void)didLoadAdOfType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeIncentivized: {
            self.incentivizedError = nil;
            break;
        }
        case HZCreativeTypeStatic: {
            // This won't be called because we're not being notified for interstitials.
            break;
        }
        case HZCreativeTypeBanner:
        case HZCreativeTypeVideo:
        case HZCreativeTypeNative:
        case HZCreativeTypeUnknown: {
            // Ignored
            break;
        }
    }
}

- (void)didFailToLoadAdOfType:(HZCreativeType)creativeType error:(NSError *)error
{
    switch (creativeType) {
        case HZCreativeTypeIncentivized: {
            self.incentivizedDelegate = nil;
            self.currentIncentivizedAd = nil;
            self.incentivizedError = error;
            
            break;
        }
        case HZCreativeTypeStatic: {
            // This won't be called because we're not being notified for interstitials.
            break;
        }
            
        case HZCreativeTypeBanner:
        case HZCreativeTypeVideo:
        case HZCreativeTypeNative:
        case HZCreativeTypeUnknown: {
            // Ignored
            break;
        }
    }
}

- (void)didShowAd {
    [self.delegate adapterDidShowAd:self];
}

- (void)didClickAd
{
    [self.delegate adapterWasClicked:self];
}

- (void)didDismissAdOfType:(HZCreativeType)creativeType
{
    [self.delegate adapterDidDismissAd:self];
    if(creativeType == HZCreativeTypeIncentivized) {
        [self clearIncentivizedState];
    } else if (creativeType == HZCreativeTypeStatic) {
        self.currentInterstitialAd = nil;
    }
}

- (void)didCompleteIncentivized
{
    [self.delegate adapterDidCompleteIncentivizedAd:self];
}

- (void)didFailToCompleteIncentivized
{
    [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
}

- (void)clearIncentivizedState {
    self.incentivizedDelegate = nil;
    self.currentIncentivizedAd = nil;
    self.incentivizedError = nil;
}

- (void)willPlayAudio
{
    [self.delegate adapterWillPlayAudio:self];
}

- (void)didFinishAudio
{
    [self.delegate adapterDidFinishPlayingAudio:self];
}

#pragma mark - Setters/Getters

- (HZAppLovinDelegate *)interstitialDelegate {
    if (!_interstitialDelegate) {
        _interstitialDelegate = [[HZAppLovinDelegate alloc] initWithCreativeType:HZCreativeTypeStatic delegate:self.forwardingDelegate];
    }
    
    return _interstitialDelegate;
}

@end
