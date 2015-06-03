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
#import "HZALInterstitialAd.h"
#import "HZALAdService.h"
#import "HZALAd.h"
#import "HZALIncentivizedInterstitialAd.h"
#import "HZALAdSize.h"
#import "HZIncentivizedAppLovinDelegate.h"

#import "HeyzapMediation.h"
#import "HeyzapAds.h"

/**
 *  AppLovin's SDK is split between using (singletons+class methods) vs instances. Inexplicably, the former group is only available when you store the SDK Key in your info.plist file, so we need to use the instance methods.
 */
@interface HZAppLovinAdapter()

// (We either need to store the HZALSdk or the sdkKey because the ads take SDK instance as an argument)
@property (nonatomic, strong) HZALSdk *sdk;

@property (nonatomic, strong) NSString *test;

@property (nonatomic, strong) HZALIncentivizedInterstitialAd *currentIncentivizedAd;

@property (nonatomic, strong) HZAppLovinDelegate *interstitialDelegate;
@property (nonatomic, strong) HZIncentivizedAppLovinDelegate *incentivizedDelegate;

@property (nonatomic, strong) NSError *interstitialError;
@property (nonatomic, strong) NSError *incentivizedError;

@end

@implementation HZAppLovinAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
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

- (void)initializeSDKWithKey:(NSString *)key
{
    _sdk = [HZALSdk sharedWithKey:key];
    [self.sdk initializeSdk];
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

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    HZParameterAssert(credentials);
    NSError *error;
    NSString *sdkKey = [HZDictionaryUtils objectForKey:@"sdk_key" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    HZAppLovinAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
       [[self sharedInstance] initializeSDKWithKey:sdkKey];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    }

    return nil;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

// To support incentivized, I will need to have separate objects for the incentivized/interstial delegates because they received the same selectors
- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    
    switch (type) {
        case HZAdTypeInterstitial: {
            self.interstitialDelegate = [[HZAppLovinDelegate alloc] initWithAdType:HZAdTypeInterstitial delegate:self.forwardingDelegate];
            [[self.sdk adService] loadNextAd:[HZALAdSize sizeInterstitial]
                                   andNotify:self.interstitialDelegate];
            break;
        }
        case HZAdTypeIncentivized: {
            if (self.currentIncentivizedAd) {
                return;
            }
            self.currentIncentivizedAd = [[HZALIncentivizedInterstitialAd alloc] initIncentivizedInterstitialWithSdk:self.sdk];
            self.incentivizedDelegate = [[HZIncentivizedAppLovinDelegate alloc] initWithAdType:HZAdTypeIncentivized delegate:self.forwardingDelegate];
            [self.currentIncentivizedAd preloadAndNotify:self.incentivizedDelegate];
            self.currentIncentivizedAd.adVideoPlaybackDelegate = self.incentivizedDelegate;
            
            break;
        }
        case HZAdTypeBanner:
        case HZAdTypeVideo: {
            // Not supported——I believe AppLovin shows videos as part of interstitials, like us.
            break;
        }
    }
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    switch (type) {
        case HZAdTypeInterstitial: {
            return [[self.sdk adService] hasPreloadedAdOfSize:[HZALAdSize sizeInterstitial]];
            break;
        }
        case HZAdTypeIncentivized: {
            return self.currentIncentivizedAd.isReadyForDisplay;
        }
            
        case HZAdTypeBanner:
        case HZAdTypeVideo: {
            return NO;
            break;
        }
    }
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    if (type == HZAdTypeIncentivized) {
        self.currentIncentivizedAd.adDisplayDelegate = self.incentivizedDelegate;
        [self.currentIncentivizedAd showOver:[[UIApplication sharedApplication] keyWindow]
                                   andNotify:self.incentivizedDelegate];
    } else {
        HZALInterstitialAd *interstitial = [[HZALInterstitialAd alloc] initInterstitialAdWithSdk:self.sdk];
        interstitial.adDisplayDelegate = self.interstitialDelegate;
        interstitial.adVideoPlaybackDelegate = self.interstitialDelegate;
        [interstitial showOver:[[UIApplication sharedApplication] keyWindow]];
    }
}

#pragma mark - AppLovinDelegateReceiver

- (void)didLoadAdOfType:(HZAdType)type
{
    
    switch (type) {
        case HZAdTypeIncentivized: {
            self.incentivizedError = nil;
            break;
        }
        case HZAdTypeInterstitial: {
            self.interstitialError = nil;
            break;
        }
            
        case HZAdTypeBanner:
        case HZAdTypeVideo: {
            // Ignored
            break;
        }
    }
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}
- (void)didFailToLoadAdOfType:(HZAdType)type error:(NSError *)error
{
    switch (type) {
        case HZAdTypeIncentivized: {
            self.incentivizedDelegate = nil;
            self.currentIncentivizedAd = nil;
            self.incentivizedError = error;
            
            break;
        }
        case HZAdTypeInterstitial: {
            self.interstitialError = error;
            break;
        }
            
        case HZAdTypeBanner:
        case HZAdTypeVideo: {
            // Ignored
            break;
        }
    }
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)didShowAd {
    [self.delegate adapterDidShowAd:self];
}

- (void)didClickAd
{
    [self.delegate adapterWasClicked:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self name]];
}
- (void)didDismissAd
{
    [self.delegate adapterDidDismissAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackHide forNetwork: [self name]];
}

- (void)didCompleteIncentivized
{
    [self clearIncentivizedState];
    
    [self.delegate adapterDidCompleteIncentivizedAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultComplete forNetwork: [self name]];
}
- (void)didFailToCompleteIncentivized
{
    [self clearIncentivizedState];
    [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultIncomplete forNetwork: [self name]];
}

- (void)clearIncentivizedState {
    self.incentivizedDelegate = nil;
    self.currentIncentivizedAd = nil;
    self.incentivizedError = nil;
}

- (void)willPlayAudio
{
    [self.delegate adapterWillPlayAudio:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioStarting forNetwork: [self name]];
}
- (void)didFinishAudio
{
    [self.delegate adapterDidFinishPlayingAudio:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioFinished forNetwork: [self name]];
}


@end
