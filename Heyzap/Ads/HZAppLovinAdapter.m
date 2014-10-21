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

@property (nonatomic) BOOL incentivizedIsLoaded;

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
    return kHZAdapterAppLovin;
}

+ (NSString *)humanizedName
{
    return kHZAdapterAppLovinHumanized;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    NSParameterAssert(credentials);
    NSError *error;
    NSString *const sdkKey = [HZDictionaryUtils objectForKey:@"sdk_key" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    [[self sharedInstance] initializeSDKWithKey:sdkKey];
    
    return nil;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeIncentivized;
}

// To support incentivized, I will need to have separate objects for the incentivized/interstial delegates because they received the same selectors
- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    
    switch (type) {
        case HZAdTypeInterstitial: {
            self.interstitialDelegate = [[HZAppLovinDelegate alloc] initWithAdType:HZAdTypeInterstitial delegate:self];
            [[self.sdk adService] loadNextAd:[HZALAdSize sizeInterstitial]
                                   andNotify:self.interstitialDelegate];
            break;
        }
        case HZAdTypeIncentivized: {
            if (self.currentIncentivizedAd) {
                return;
            }
            self.currentIncentivizedAd = [[HZALIncentivizedInterstitialAd alloc] initIncentivizedInterstitialWithSdk:self.sdk];
            self.incentivizedDelegate = [[HZIncentivizedAppLovinDelegate alloc] initWithAdType:HZAdTypeIncentivized delegate:self];
            [self.currentIncentivizedAd preloadAndNotify:self.incentivizedDelegate];
            self.currentIncentivizedAd.adVideoPlaybackDelegate = self.incentivizedDelegate;
            
            break;
        }
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
            return self.incentivizedIsLoaded;
            break;
        }
        case HZAdTypeVideo: {
            return NO;
            break;
        }
    }
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (type == HZAdTypeIncentivized) {
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
            self.incentivizedIsLoaded = YES;
            self.incentivizedError = nil;
            break;
        }
        case HZAdTypeInterstitial: {
            self.interstitialError = nil;
            break;
        }
        case HZAdTypeVideo: {
            // Ignored
            break;
        }
    }
}
- (void)didFailToLoadAdOfType:(HZAdType)type error:(NSError *)error
{
    switch (type) {
        case HZAdTypeIncentivized: {
            self.incentivizedIsLoaded = NO;
            self.incentivizedDelegate = nil;
            self.currentIncentivizedAd = nil;
            self.incentivizedError = error;
            
            break;
        }
        case HZAdTypeInterstitial: {
            self.interstitialError = error;
            break;
        }
        case HZAdTypeVideo: {
            // Ignored
            break;
        }
    }
}

- (void)didClickAd
{
    [self.delegate adapterWasClicked:self];
}
- (void)didDismissAd
{
    [self.delegate adapterDidDismissAd:self];
}

- (void)didCompleteIncentivized
{
    self.incentivizedIsLoaded = NO;
    self.incentivizedDelegate = nil;
    self.currentIncentivizedAd = nil;
    self.incentivizedError = nil;
    
    [self.delegate adapterDidCompleteIncentivizedAd:self];
}
- (void)didFailToCompleteIncentivized
{
    [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
}

- (void)willPlayAudio
{
    [self.delegate adapterWillPlayAudio:self];
}
- (void)didFinishAudio
{
    [self.delegate adapterDidFinishPlayingAudio:self];
}


@end
