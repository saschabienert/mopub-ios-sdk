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

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeStatic:
        case HZCreativeTypeVideo: {
            HZGADInterstitial *currentAd = self.adDictionary[@(creativeType)];
            return currentAd && currentAd.isReady;
        }
        default:
            return NO;
    }
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeStatic | HZCreativeTypeVideo | HZCreativeTypeBanner;
}

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            return self.interstitialAdUnitID != nil;
        }
        case HZCreativeTypeVideo: {
            return self.videoAdUnitID != nil;
        }
        case HZCreativeTypeBanner: {
            return self.bannerAdUnitID != nil;
        }
        default:
            return NO;
    }
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            HZAssert(self.interstitialAdUnitID, @"Need an interstitial ad unit ID by this point");
            break;
        }
        case HZCreativeTypeVideo: {
            HZAssert(self.videoAdUnitID, @"Need a video ad unit ID by this point");
            break;
        }
        default: {
            return;
        }
    }
    
    HZGADInterstitial *currentAd = self.adDictionary[@(creativeType)];
    NSError *currentError = [self lastErrorForCreativeType:creativeType];
    if (currentAd
        && !currentAd.hasBeenUsed
        && !currentError) {
        // If we have an ad already out fetching, don't start up a re-fetch.
        return;
    }
    
    HZGADInterstitial *newAd = [[HZGADInterstitial alloc] init];
    self.adDictionary[@(creativeType)] = newAd;
    
    HZDLog(@"Initializing AdMob Ad with interstitialAdUnitID Ad Unit ID: %@",self.interstitialAdUnitID);
    
    newAd.adUnitID = (creativeType == HZCreativeTypeStatic) ? self.interstitialAdUnitID : self.videoAdUnitID;
    newAd.delegate = self.forwardingDelegate;
    
    HZGADRequest *request = [HZGADRequest request];
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    [newAd loadRequest:request];
}

- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    if(![self supportsCreativeType:creativeType]) return;

    HZGADInterstitial *ad = self.adDictionary[@(creativeType)];
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
    const HZCreativeType creativeType = [self creativeTypeForAd:ad];
    [self.adDictionary removeObjectForKey:@(creativeType)];
    
    NSError *wrappedError = [NSError errorWithDomain:kHZMediationDomain
                                                code:1
                                            userInfo:@{kHZMediatorNameKey: @"AdMob",
                                                       NSUnderlyingErrorKey: error}];
    if (creativeType == HZCreativeTypeStatic) {
        self.lastStaticError = wrappedError;
    } else if (creativeType == HZCreativeTypeVideo) {
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
    
    [self.adDictionary removeObjectForKey:@([self creativeTypeForAd:ad])];
}

// As far as I can tell, this means a click.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad
{
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    [self clearErrorForCreativeType:[self creativeTypeForAd:ad]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZAdMobBannerAdapter alloc] initWithAdUnitID:self.bannerAdUnitID options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

- (HZCreativeType)creativeTypeForAd:(HZGADInterstitial *)ad {
    if ([ad.adUnitID isEqualToString:self.interstitialAdUnitID]) {
        return HZCreativeTypeStatic;
    } else {
        return HZCreativeTypeVideo;
    }
}

@end
