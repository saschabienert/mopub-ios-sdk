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

@property (nonatomic, strong) HZGADInterstitial *currentInterstitial;

@property (nonatomic, strong) NSString *adUnitID;
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

- (void)loadCredentials {
    self.adUnitID = [HZDictionaryUtils objectForKey:@"ad_unit_id" ofClass:[NSString class] dict:self.credentials];
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
        case HZAdTypeInterstitial: {
            return self.currentInterstitial.isReady;
        }
        case HZAdTypeVideo:
        case HZAdTypeIncentivized:
        case HZAdTypeBanner: {
            return NO;
        }
            
    }
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeBanner;
}

- (BOOL)hasCredentialsForAdType:(HZAdType)adType {
    switch (adType) {
        case HZAdTypeInterstitial: {
            return self.adUnitID != nil;
        }
        case HZAdTypeVideo: {
            return NO;
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
    HZAssert(self.adUnitID, @"Need an ad unit ID by this point");
    if (self.currentInterstitial
        && !self.currentInterstitial.hasBeenUsed
        && !self.lastInterstitialError) {
        // If we have an interstitial already out fetching, don't start up a re-fetch.
        return;
    }
    
    self.currentInterstitial = [[HZGADInterstitial alloc] init];
    HZDLog(@"Initializing AdMob ad with Ad Unit ID: %@",self.adUnitID);
    self.currentInterstitial.adUnitID = self.adUnitID;
    self.currentInterstitial.delegate = self.forwardingDelegate;
    
    [self.currentInterstitial loadRequest:[HZGADRequest request]];
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    switch (type) {
        case HZAdTypeInterstitial: {
            [self.currentInterstitial presentFromRootViewController:options.viewController];
        }
        case HZAdTypeVideo:
        case HZAdTypeIncentivized:
        case HZAdTypeBanner: {
            // Ignored
        }
    }
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
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain
                                         code:1
                                     userInfo:@{kHZMediatorNameKey: @"AdMob",
                                                NSUnderlyingErrorKey: error}];
    self.currentInterstitial = nil;
    
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
    self.currentInterstitial = nil;
}

// As far as I can tell, this means a click.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad
{
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    self.lastInterstitialError = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZAdMobBannerAdapter alloc] initWithAdUnitID:self.bannerAdUnitID options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

@end
