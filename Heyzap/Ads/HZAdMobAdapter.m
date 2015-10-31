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
#import "HZBaseAdapter_Internal.h"
#import "HZShowOptions_Private.h"

@interface HZAdMobAdapter() <HZGADInterstitialDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableDictionary <NSString *, HZGADInterstitial *> *> *adDictionary; // outer key: creativeType, inner key: placement ID

@property (nonatomic, strong) NSString *interstitialAdUnitID;
@property (nonatomic, strong) NSString *videoAdUnitID;
@property (nonatomic, strong) NSString *bannerAdUnitID;

@end

@implementation HZAdMobAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
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

- (NSError *)internalInitializeSDK {
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

- (BOOL)internalHasAdForCreativeType:(HZCreativeType)creativeType placementIDOverride:(NSString *)placementIDOverride
{
    HZGADInterstitial *ad = [self adForCreativeType:creativeType placementIDOverride:placementIDOverride];
    return ad && ad.isReady;
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

- (void)internalPrefetchForCreativeType:(HZCreativeType)creativeType options:(HZFetchOptions *)options
{
    NSString *adUnitID;
    
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            adUnitID = options.placementIDOverride ?: self.interstitialAdUnitID;
            HZAssert(adUnitID, @"Need an interstitial ad unit ID by this point");
            
            break;
        }
        case HZCreativeTypeVideo: {
            adUnitID = options.placementIDOverride ?: self.videoAdUnitID;
            HZAssert(adUnitID, @"Need a video ad unit ID by this point");
            break;
        }
        default: {
            return;
        }
    }
    
    HZGADInterstitial *currentAd = [self adForCreativeType:creativeType placementIDOverride:adUnitID];
    if (currentAd
        && !currentAd.hasBeenUsed) {
        // If we have an ad already out fetching, don't start up a re-fetch.
        return;
    }
    
    HZDLog(@"Initializing AdMob Ad with %@AdUnitID: %@", (creativeType == HZCreativeTypeStatic ? @"interstitial" : @"video") ,adUnitID);
    
    HZGADInterstitial *newAd;
    
    if ([HZGADInterstitial respondsToSelector:@selector(initWithAdUnitID:)]) {
        newAd = [[HZGADInterstitial alloc] initWithAdUnitID:adUnitID];
    } else {
        newAd = [[HZGADInterstitial alloc] init];
        [newAd setAdUnitID:adUnitID];
    }
    
    newAd.delegate = self.forwardingDelegate;
    [self setAd:newAd forCreativeType:creativeType placementID:adUnitID];
    
    HZGADRequest *request = [HZGADRequest request];
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    [newAd loadRequest:request];
}

- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    HZGADInterstitial *ad = [self adForCreativeType:creativeType placementIDOverride:options.placementIDOverride];
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
    [self setAd:nil forCreativeType:creativeType placementID:ad.adUnitID];
    
    NSError *wrappedError = [NSError errorWithDomain:kHZMediationDomain
                                                code:1
                                            userInfo:@{kHZMediatorNameKey: @"AdMob",
                                                       NSUnderlyingErrorKey: error}];
    
    [self setLastFetchError:wrappedError forCreativeType:creativeType];
    
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
    
    [self setAd:nil forCreativeType:[self creativeTypeForAd:ad] placementID:ad.adUnitID];
}

// As far as I can tell, this means a click.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad
{
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    [self clearLastFetchErrorForCreativeType:[self creativeTypeForAd:ad]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZAdMobBannerAdapter alloc] initWithAdUnitID:self.bannerAdUnitID options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

- (HZCreativeType)creativeTypeForAd:(HZGADInterstitial *)ad {
    NSArray *supportedCreativeTypes = @[@(HZCreativeTypeStatic), @(HZCreativeTypeVideo)];
    
    for (NSNumber *creativeTypeNumber in supportedCreativeTypes) {
        if (self.adDictionary[creativeTypeNumber] && [[self.adDictionary[creativeTypeNumber] allValues] containsObject:ad]) {
            return hzCreativeTypeFromNSNumber(creativeTypeNumber);
        }
    }
    
    HZELog(@"AdMob adapter in an unexpected state... it was looking for the creativeType for an ad in it's inventory, but no ad was present. Please report this to support@heyzap.com . Ad: %@", ad);
    return HZCreativeTypeUnknown;
}

#pragma mark - Utilities

- (HZGADInterstitial *) adForCreativeType:(HZCreativeType)creativeType placementIDOverride:(NSString *)placementIDOverride {
    NSString *placementIDToUse = placementIDOverride ?: (creativeType == HZCreativeTypeStatic ? self.interstitialAdUnitID : self.videoAdUnitID);
    
    if (!placementIDToUse) {
        return nil;
    }
    
    NSMutableDictionary *adsForCreativeType = self.adDictionary[@(creativeType)];
    
    if (!adsForCreativeType) {
        return nil;
    } else {
        return adsForCreativeType[placementIDToUse];
    }
}

- (void) setAd:(HZGADInterstitial *)ad forCreativeType:(HZCreativeType)creativeType placementID:(NSString *)placementID {
    NSMutableDictionary * adsForCreativeType = self.adDictionary[@(creativeType)];
    if (!adsForCreativeType) {
        adsForCreativeType = [[NSMutableDictionary alloc] init];
        self.adDictionary[@(creativeType)] = adsForCreativeType;
    }
    if (ad) {
        adsForCreativeType[placementID] = ad;
    } else {
        [adsForCreativeType removeObjectForKey:placementID];
    }
}

@end
