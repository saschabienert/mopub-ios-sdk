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
#import "HZBaseAdapter_Internal.h"

@interface HZiAdAdapter()<ADInterstitialAdDelegate>

@property (nonatomic, strong) ADInterstitialAd *interstitialAd;
@property (nonatomic, weak) UIViewController *presentedViewController;

@end

@implementation HZiAdAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
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

- (NSError *)internalInitializeSDK {
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

- (void)internalPrefetchForCreativeType:(HZCreativeType)creativeType {
    if (self.interstitialAd == nil) {
        self.interstitialAd = [[ADInterstitialAd alloc] init];
        self.interstitialAd.delegate = self.forwardingDelegate;
    }
}

- (BOOL)internalHasAdForCreativeType:(HZCreativeType)creativeType
{
    return [self.interstitialAd isLoaded];
}

- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options {
    BOOL success = NO;
    
    if ([options.viewController respondsToSelector:@selector(requestInterstitialAdPresentation)]) {
        success = [options.viewController requestInterstitialAdPresentation];
    }
    
    if (!success) {
        [self.interstitialAd presentFromViewController:options.viewController];
    }
    
    [self.delegate adapterDidShowAd:self];
    [self.delegate adapterWillPlayAudio:self];

    self.presentedViewController = options.viewController.presentedViewController;
    [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(checkIfAdIsVisible:) userInfo:nil repeats:YES];
}

/**
 * We use this timer to poll for the iAd on the view controller and call dismiss once we no longer see it.
 * This is done because the `interstitialAdDidUnload` doesn't necessarily get called when an interstitial gets dismissed after it's been displayed (see comment above `interstitialAdDidUnload`)
 */
- (void)checkIfAdIsVisible:(NSTimer *)timer {
    // It's possible we've already sent the dismiss callback via `interstitialAdDidUnload:`
    // If so `interstitialAd` will be `nil` and we've already sent the `adapterDidDismissAd:` callback.
    if (!self.interstitialAd) {
        [timer invalidate];
        
    }else if (![self.presentedViewController presentingViewController]) {
        [timer invalidate];
        [self adWasDismissed];
    }
}

- (HZCreativeType) supportedCreativeTypes
{
    if ([HZDevice hzSystemVersionIsLessThan:@"7.0"] && [HZDevice isPhone]) {
        return HZCreativeTypeBanner;
        
    } else {
        return HZCreativeTypeStatic | HZCreativeTypeBanner;
    }
}

- (void)adWasDismissed {
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
    self.interstitialAd = nil;
    self.presentedViewController = nil;
}

#pragma mark - ADInterstitialAdDelegate

- (void)interstitialAdWillLoad:(ADInterstitialAd *)interstitialAd {
}

- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd {
    [self clearLastFetchErrorForCreativeType:HZCreativeTypeStatic];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

/**
 * Note: This gets called when an interstitial ad's data is unloaded (i.e. because of an error, memory issue, or the ad just expiring after it has been loaded for a long time). It does not necessarily get called when the ad gets dismissed after being presented.
 */
- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    
    if (self.presentedViewController) { // this got called sometime after we displayed an Ad
        [self adWasDismissed];
        
    } else {
        self.interstitialAd = nil;
    }
}

- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd
                   willLeaveApplication:(BOOL)willLeave {
    [self.delegate adapterWasClicked: self];
    
    if (willLeave) {
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: [self name]];
    }
    
    return YES;
}

/*
 * Called only after the Ad gets dismissed after being clicked on.
 */
- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd {
}

- (void)interstitialAd:(ADInterstitialAd *)interstitialAd
      didFailWithError:(NSError *)error {
    
    [self setLastFetchError:[NSError errorWithDomain:kHZMediationDomain
                                                code:1
                                            userInfo:@{kHZMediatorNameKey: @"iAd", NSUnderlyingErrorKey: error}]
            forCreativeType:HZCreativeTypeStatic];
    self.interstitialAd = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

# pragma mark - Banners

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZiAdBannerAdapter alloc] initWithReportingDelegate:reportingDelegate parentAdapter:self options:options];
}

@end
