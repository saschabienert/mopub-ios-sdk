//
//  HZAdMobProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdMobAdapter.h"
#import "HZGADInterstitial.h"
#import "HZGADRequest.h"
#import <UIKit/UIKit.h>
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZAdMobBannerAdapter.h"
#import "HeyzapMediation.h"
#import "HeyzapAds.h"

@interface HZAdMobAdapter() <HZGADInterstitialDelegate>

@property (nonatomic, strong) NSMutableDictionary *adDictionary;

@property (nonatomic, strong) NSString *interstitialAdUnitID;
@property (nonatomic, strong) NSString *videoAdUnitID;
@property (nonatomic, strong) NSString *bannerAdUnitID;

@end

@implementation HZAdMobAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZAdMobAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZAdMobAdapter alloc] init];
        proxy.forwardingDelegate = [HZAdapterDelegate new];
        proxy.forwardingDelegate.adapter = proxy;
    });
    return proxy;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _adDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)loadCredentials {
    self.interstitialAdUnitID = [HZDictionaryUtils objectForKey:@"ad_unit_id" ofClass:[NSString class] dict:self.credentials];
    self.videoAdUnitID = [HZDictionaryUtils objectForKey:@"video_ad_unit_id" ofClass:[NSString class] dict:self.credentials];
    self.bannerAdUnitID = [HZDictionaryUtils objectForKey:@"banner_ad_unit_id" ofClass:[NSString class] dict:self.credentials];
}

#pragma mark - Adapter Protocol

- (NSError *)initializeSDK {
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZGADInterstitial hzProxiedClassIsAvailable] && [HZGADRequest hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return HZNetworkAdMob;
}

+ (NSString *)humanizedName
{
    return kHZAdapterAdMobHumanized;
}

+ (NSString *)sdkVersion {
    return [HZGADRequest sdkVersion];
}

- (BOOL)hasAdForType:(HZAdType)type
{
    switch (type) {
        
        case HZAdTypeIncentivized:
        case HZAdTypeBanner: {
            return NO;
        }
        case HZAdTypeInterstitial:
        case HZAdTypeVideo: {
            HZGADInterstitial *currentAd = self.adDictionary[@(type)];
            return currentAd.isReady;
        }
    }
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeBanner;
}

- (BOOL)hasCredentialsForAdType:(HZAdType)adType {
    switch (adType) {
        case HZAdTypeInterstitial: {
            return self.interstitialAdUnitID != nil;
        }
        case HZAdTypeVideo: {
            return self.videoAdUnitID != nil;
        }
        case HZAdTypeBanner: {
            return self.bannerAdUnitID != nil;
        }
        case HZAdTypeIncentivized: {
            return NO;
        }
    }
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

- (void)prefetchForType:(HZAdType)type
{
    switch (type) {
        case HZAdTypeInterstitial: {
            HZAssert(self.interstitialAdUnitID, @"Need an interstitial ad unit ID by this point");
            break;
        }
        case HZAdTypeVideo: {
            HZAssert(self.videoAdUnitID, @"Need a video ad unit ID by this point");
            break;
        }
        case HZAdTypeBanner:
        case HZAdTypeIncentivized: {
            return;
        }
    }
    
    HZGADInterstitial *currentAd = self.adDictionary[@(type)];
    NSError *currentError = [self lastErrorForAdType:type];
    if (currentAd
        && !currentAd.hasBeenUsed
        && !currentError) {
        // If we have an ad already out fetching, don't start up a re-fetch.
        return;
    }
    
    HZGADInterstitial *newAd = [[HZGADInterstitial alloc] init];
    self.adDictionary[@(type)] = newAd;
    
    HZDLog(@"Initializing AdMob Ad with interstitialAdUnitID Ad Unit ID: %@",self.interstitialAdUnitID);
    
    newAd.adUnitID = type == HZAdTypeInterstitial ? self.interstitialAdUnitID : self.videoAdUnitID;
    newAd.delegate = self.forwardingDelegate;
    
    HZGADRequest *request = [HZGADRequest request];
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    [newAd loadRequest:request];
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    HZGADInterstitial *ad = self.adDictionary[@(type)];
    [ad presentFromRootViewController:options.viewController];
}

#pragma mark - Delegate callbacks

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"GADInterstitialDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)interstitial:(HZGADInterstitial *)ad didFailToReceiveAdWithError:(HZGADRequestError *)error
{
    const HZAdType type = [self adTypeForAd:ad];
    [self.adDictionary removeObjectForKey:@(type)];
    
    NSError *wrappedError = [NSError errorWithDomain:kHZMediationDomain
                                         code:1
                                     userInfo:@{kHZMediatorNameKey: @"AdMob",
                                                NSUnderlyingErrorKey: error}];
    if (type == HZAdTypeInterstitial) {
        self.lastInterstitialError = wrappedError;
    } else if (type == HZAdTypeVideo) {
        self.lastVideoError = wrappedError;
    }
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)interstitialWillPresentScreen:(HZGADInterstitial *)ad {
    [self.delegate adapterDidShowAd:self];
    [self.delegate adapterWillPlayAudio:self];
}

- (void)interstitialDidDismissScreen:(HZGADInterstitial *)ad
{
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
    
    [self.adDictionary removeObjectForKey:@([self adTypeForAd:ad])];
}

// As far as I can tell, this means a click.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad
{
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    [self clearErrorForAdType:[self adTypeForAd:ad]];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZAdMobBannerAdapter alloc] initWithAdUnitID:self.bannerAdUnitID options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

- (HZAdType)adTypeForAd:(HZGADInterstitial *)ad {
    if ([ad.adUnitID isEqualToString:self.interstitialAdUnitID]) {
        return HZAdTypeInterstitial;
    } else {
        return HZAdTypeVideo;
    }
}

@end
