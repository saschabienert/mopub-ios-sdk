//
//  HZFacebookAdapter.m
//  Heyzap
//
//  Created by David Stumm on 12/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZFacebookAdapter.h"
#import "HZFBInterstitialAd.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZBannerAd.h"
#import "HZFBAdView.h"
#import "HZFBBannerAdapter.h"
#import "HZBannerAdOptions.h"
#import "HZBannerAdOptions_Private.h"
#import "HeyzapMediation.h"
#import "HeyzapAds.h"
#import "HZBaseAdapter_Internal.h"
#import "HZFBAdSettings.h"

@interface HZFacebookAdapter() <HZFBInterstitialAdDelegate>
@property (nonatomic, strong) NSString *placementID;
@property (nonatomic, strong) NSString *bannerPlacementID;
@property (nonatomic, strong) HZFBInterstitialAd *interstitialAd;
@end

@implementation HZFacebookAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter {
    static HZFacebookAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZFacebookAdapter alloc] init];
        proxy.forwardingDelegate = [HZAdapterDelegate new];
        proxy.forwardingDelegate.adapter = proxy;
    });
    return proxy;
}

- (void)loadCredentials {
    self.placementID = [HZDictionaryUtils
                        objectForKey:@"placement_id"
                        ofClass:[NSString class]
                        dict:self.credentials];
    self.bannerPlacementID = [HZDictionaryUtils
                              objectForKey:@"banner_placement_id"
                              ofClass:[NSString class]
                              dict:self.credentials];
}

- (void) toggleLogging {
    [HZFBAdSettings setLogLevel:([self isLoggingEnabled] ? HZFBAdLogLevelVerbose : HZFBAdLogLevelError)]; // leave error logs on
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable {
    return [HZFBInterstitialAd hzProxiedClassIsAvailable]
    && [HZFBAdView hzProxiedClassIsAvailable];
}

+ (NSString *)name {
    return HZNetworkFacebook;
}

+ (NSString *) humanizedName {
    return kHZAdapterFacebookHumanized;
}

+ (NSString *)sdkVersion {
    return nil;
}

- (NSError *)internalInitializeSDK {
    [self toggleLogging];
    return nil;
}

- (NSString *)testActivityInstructions {
    return @"Facebook Audience Network will only show ads if you have Facebook installed and are logged in, or are using a simulator. You can use [FBAdSettings addTestDevice:<device hash>] to work around this. FAN will print your device hash to the Xcode console.";
}

- (HZCreativeType) supportedCreativeTypes {
    return HZCreativeTypeStatic | HZCreativeTypeBanner;
}

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            return self.placementID != nil;
        }
        case HZCreativeTypeBanner: {
            return self.bannerPlacementID != nil;
        }
            
        default: {
            return NO;
        }
    }
}

- (BOOL)internalHasAdForCreativeType:(HZCreativeType)creativeType {
    return creativeType == HZCreativeTypeStatic && self.interstitialAd && self.interstitialAd.isAdValid;
}

- (void)internalPrefetchForCreativeType:(HZCreativeType)creativeType {
    HZAssert(self.placementID, @"Need a Placement ID by this point");
    
    if (self.interstitialAd) {
        // If we have an interstitial already out fetching, don't start up a re-fetch. This differs from the `hasAdForCreativeType:` check because we don't check `isAdValid`.
        return;
    }
    
    HZDLog(@"Initializing Facebook Audience Network interstitial ad with placement ID: %@",self.placementID);
    self.interstitialAd = [[HZFBInterstitialAd alloc] initWithPlacementID:self.placementID];
    self.interstitialAd.delegate = self.forwardingDelegate;
    [self.interstitialAd loadAd];
}

- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options {
    [self.interstitialAd showAdFromRootViewController:options.viewController];
}

#pragma mark - Facebook Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"FBInterstitialAdDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)interstitialAdDidClick:(HZFBInterstitialAd *)interstitialAd {
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialAdDidClose:(HZFBInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd:self];
    self.interstitialAd = nil;
}

- (void)interstitialAdWillClose:(HZFBInterstitialAd *)interstitialAd {
    
}

- (void)interstitialAdDidLoad:(HZFBInterstitialAd *)interstitialAd {
    [self clearLastFetchErrorForCreativeType:HZCreativeTypeStatic];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void)interstitialAd:(HZFBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    [self setLastFetchError:[NSError errorWithDomain:kHZMediationDomain
                                                code:1
                                            userInfo:@{kHZMediatorNameKey: @"Facebook", NSUnderlyingErrorKey: error}]
            forCreativeType:HZCreativeTypeStatic];
    self.interstitialAd = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)interstitialAdWillLogImpression:(HZFBInterstitialAd *)interstitialAd {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFacebookLoggingImpression forNetwork: [self name]];
    [self.delegate adapterDidShowAd:self];
}

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZFBBannerAdapter alloc] initWithAdUnitId:self.bannerPlacementID options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

@end
