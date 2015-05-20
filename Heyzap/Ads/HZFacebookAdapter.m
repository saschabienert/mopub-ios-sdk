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

@interface HZFacebookAdapter() <HZFBInterstitialAdDelegate>
@property (nonatomic, strong) NSString *placementID;
@property (nonatomic, strong) NSString *bannerPlacementID;
@property (nonatomic, strong) HZFBInterstitialAd *interstitialAd;
@end

@implementation HZFacebookAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance {
    static HZFacebookAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZFacebookAdapter alloc] init];
        proxy.forwardingDelegate = [HZAdapterDelegate new];
        proxy.forwardingDelegate.adapter = proxy;
    });
    return proxy;
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable {
    return [HZFBInterstitialAd hzProxiedClassIsAvailable]
    && [HZFBAdView hzProxiedClassIsAvailable]
    && [HZBannerAdOptions facebookBannerSizesAvailable];
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

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials {
    HZParameterAssert(credentials);
    NSError *error;
    
    NSString *placementID = [HZDictionaryUtils
                             objectForKey:@"placement_id"
                             ofClass:[NSString class]
                             dict:credentials
                             error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    // Nullable
    NSString *const bannerPlacementID = [HZDictionaryUtils hzObjectForKey:@"banner_placement_id"
                                                                  ofClass:[NSString class]
                                                                 withDict:credentials];
    
    HZFacebookAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        adapter.placementID = placementID;
        adapter.bannerPlacementID = bannerPlacementID;
    }
    
    return nil;
}

- (HZAdType)supportedAdFormats {
    return HZAdTypeInterstitial | HZAdTypeBanner;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag {
    return type == HZAdTypeInterstitial && self.interstitialAd && self.interstitialAd.isAdValid;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag {
    HZAssert(self.placementID, @"Need a Placement ID by this point");
    
    if (type != HZAdTypeInterstitial) {
        // only prefetch if they want an interstitial
        return;
    }
    
    if (self.interstitialAd
        && !self.lastInterstitialError) {
        // If we have an interstitial already out fetching, don't start up a re-fetch.
        return;
    }
    
    self.interstitialAd = [[HZFBInterstitialAd alloc] initWithPlacementID:self.placementID];
    self.interstitialAd.delegate = self.forwardingDelegate;
    [self.interstitialAd loadAd];
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options {
    if (type != HZAdTypeInterstitial) {
        //can only show interstitials
        return;
    }
    
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
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self name]];
}

- (void)interstitialAdDidClose:(HZFBInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd:self];
    self.interstitialAd = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackHide forNetwork: [self name]];
}

- (void)interstitialAdWillClose:(HZFBInterstitialAd *)interstitialAd {
    
}

- (void)interstitialAdDidLoad:(HZFBInterstitialAd *)interstitialAd {
    self.lastInterstitialError = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void)interstitialAd:(HZFBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain
                                                     code:1
                                                 userInfo:@{kHZMediatorNameKey: @"Facebook",
                                                            NSUnderlyingErrorKey: error}];
    self.interstitialAd = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)interstitialAdWillLogImpression:(HZFBInterstitialAd *)interstitialAd {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"logging_impression" forNetwork: [self name]];
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZFBBannerAdapter alloc] initWithAdUnitId:self.bannerPlacementID options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

- (BOOL)hasBannerCredentials {
    return self.bannerPlacementID != nil;
}

@end
