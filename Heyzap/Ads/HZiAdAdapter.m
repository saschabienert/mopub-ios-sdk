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
#import "HZDevice.h"

@interface HZiAdAdapter()<ADInterstitialAdDelegate>

@property (nonatomic, strong) ADInterstitialAd *interstitialAd;
@property (nonatomic, weak) UIViewController *presentedViewController;

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
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    return nil;
}

+ (NSString *)name
{
    return HZNetworkIAd;
}

+ (NSString *)humanizedName
{
    return kHZAdapteriAdHumanized;
}

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat: @"%@", [UIDevice currentDevice].systemVersion];
}

- (void)prefetchForType:(HZAdType)type {
    if (type != HZAdTypeInterstitial) {
        return;
    }
    
    if (self.interstitialAd == nil) {
        self.interstitialAd = [[ADInterstitialAd alloc] init];
        self.interstitialAd.delegate = self.forwardingDelegate;
    }
}

- (BOOL)hasAdForType:(HZAdType)type
{
    if (type != HZAdTypeInterstitial) {
        return NO;
    }
    
    return [self.interstitialAd isLoaded];
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
        // Note: This should be changed once we support iOS 7+
        // [UIViewController requestInterstitialAdPresentation] should be used instead (see ADInterstitialAd docs)
        [self.interstitialAd presentFromViewController:options.viewController];
    }
    
    [self.delegate adapterDidShowAd:self];
    [self.delegate adapterWillPlayAudio:self];

    self.presentedViewController = options.viewController.presentedViewController;
    [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(checkIfAdIsVisible:) userInfo:nil repeats:YES];
}

/* It turns out that the ADInterstitialAdDelegate callbacks don't work properly
 * The `interstitialAdDidUnload` callback does not fire when an ad is dismissed
 * Furthermore, the `interstitialAdActionDidFinish` *does* get fired when the ad is dismissed after clicking on it.
 * Therefore this timer will just check to see if the ad was dismissed by checking the ad's view controller.
 * Placing an `adWasDismissed` inside interstitialAdActionDidFinish ends up firing the dismissed callback twice
 * See ADInterstitialAdDelegate docs
 * Please git blame and revert changes after this bug is resolved. */

- (void)checkIfAdIsVisible:(NSTimer *)timer {
    // It's possible we've already sent the dismiss callback via `interstitialAdDidUnload:`
    // If so `interstitialAd` will be `nil` and we've already sent the `adapterDidDismissAd:` callback.
    if (!self.interstitialAd) {
        [timer invalidate];
    }
    if (![self.presentedViewController presentingViewController]) {
        [timer invalidate];
        [self adWasDismissed];
    }
}

- (HZAdType)supportedAdFormats
{
    if ([HZDevice hzSystemVersionIsLessThan:@"7.0"] && [HZDevice isPhone]) {
        return HZAdTypeBanner;
        
    } else {
        return HZAdTypeInterstitial | HZAdTypeBanner;
    }
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

#pragma mark - ADInterstitialAdDelegate

- (void)interstitialAdWillLoad:(ADInterstitialAd *)interstitialAd {
}

- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd {
    self.lastInterstitialError = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    [self adWasDismissed]; // Here just in case it fires due to an error (see ADInterstitialAdDelegate docs)
}

- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd
                   willLeaveApplication:(BOOL)willLeave {
    [self.delegate adapterWasClicked: self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self name]];
    
    if (willLeave) {
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: [self name]];
    }
    
    return YES;
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd {
}

- (void)interstitialAd:(ADInterstitialAd *)interstitialAd
      didFailWithError:(NSError *)error {
    
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain
                                                     code:1
                                                 userInfo:@{kHZMediatorNameKey: @"iAd",
                                                            NSUnderlyingErrorKey: error}];
    self.interstitialAd = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZiAdBannerAdapter alloc] initWithReportingDelegate:reportingDelegate parentAdapter:self options:options];
}

- (BOOL)hasBannerCredentials {
    return YES;
}

- (void)adWasDismissed {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackDismiss forNetwork: [self name]];
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
    self.interstitialAd = nil;
    self.presentedViewController = nil;
}

@end
