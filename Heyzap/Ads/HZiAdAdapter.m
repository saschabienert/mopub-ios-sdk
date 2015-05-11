//
//  HZiAdAdapter.m
//  Heyzap
//
//  Created by Daniel Rhodes on 3/4/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZiAdAdapter.h"

@import iAd;

#import "HZMediationConstants.h"
#import "HZiAdBannerAdapter.h"
#import "HeyzapMediation.h"

@interface HZiAdAdapter()<ADInterstitialAdDelegate>

@property (nonatomic, strong) ADInterstitialAd *interstitialAd;

@end

@implementation HZiAdAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZiAdAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZiAdAdapter alloc] init];
        adapter.credentials = @{};
        adapter.forwardingDelegate = [HZAdapterDelegate new];
        adapter.forwardingDelegate.adapter = adapter;
    });
    return adapter;
}

#pragma mark - HZ methods

+ (BOOL)isSDKAvailable
{
    return YES;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials {
    return nil;
}

+ (NSString *)name
{
    return kHZAdapteriAd;
}

+ (NSString *)humanizedName
{
    return kHZAdapteriAdHumanized;
}

- (HZNetwork)network {
    return HZNetworkIAd;
}

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat: @"%@", [UIDevice currentDevice].systemVersion];
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag {
    if (type != HZAdTypeInterstitial) {
        return;
    }
    
    if (self.interstitialAd == nil) {
        self.interstitialAd = [[ADInterstitialAd alloc] init];
        self.interstitialAd.delegate = self.forwardingDelegate;
    }
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (type != HZAdTypeInterstitial) {
        return NO;
    }
    
    if (self.interstitialAd != nil) {
        return self.interstitialAd.loaded;
    }
    
    return NO;
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options {
    if (type != HZAdTypeInterstitial) {
        return;
    }
    
    BOOL success = NO;
    
    if ([options.viewController respondsToSelector:@selector(requestInterstitialAdPresentation)]) {
        success = [options.viewController requestInterstitialAdPresentation];
    }
    
    if (!success) {
        [self.interstitialAd presentFromViewController:options.viewController];
    }
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeBanner;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

#pragma mark - ADInterstitialAdDelegate

- (void)interstitialAdWillLoad:(ADInterstitialAd *)interstitialAd {
    
}

- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd {
    self.lastInterstitialError = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self network]];
}

- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd: self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackHide forNetwork: [self network]];
}

- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd
                   willLeaveApplication:(BOOL)willLeave {
    [self.delegate adapterWasClicked: self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self network]];
    
    if (willLeave) {
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: [self network]];
    }
    
    return YES;
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackDismiss forNetwork: [self network]];
}

- (void)interstitialAd:(ADInterstitialAd *)interstitialAd
      didFailWithError:(NSError *)error {
    
    
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain
                                                     code:1
                                                 userInfo:@{kHZMediatorNameKey: @"iAd",
                                                            NSUnderlyingErrorKey: error}];
    self.interstitialAd = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self network]];
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZiAdBannerAdapter alloc] initWithReportingDelegate:reportingDelegate parentAdapter:self options:options];
}

- (BOOL)hasBannerCredentials {
    return YES;
}

@end
