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

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat: @"%@", [UIDevice currentDevice].systemVersion];
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag {
    if (type != HZAdTypeInterstitial) {
        return;
    }
    
    if (self.interstitialAd == nil) {
        self.interstitialAd = [[ADInterstitialAd alloc] init];
        self.interstitialAd.delegate = self;
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
    self.presentedViewController = options.viewController.presentedViewController;
    [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(checkIfAdIsVisible:) userInfo:nil repeats:YES];
}

- (void)checkIfAdIsVisible:(NSTimer *)timer {
    // It's possible we've already sent the dismiss callback via `interstitialAdDidUnload:`
    // If so `interstitialAd` will be `nil` and we've already sent the `adapterDidDismissAd:` callback.
    if (!self.interstitialAd) {
        [timer invalidate];
    }
    if (!self.presentedViewController.presentingViewController) {
        [timer invalidate];
        [self adWasDismissed];
    }
}

- (HZAdType)supportedAdFormats
{
    if ([HZDevice hzSystemVersionIsLessThan:@"7.0.0"] && [HZDevice isPhone]) {
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
}

- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    if (self.presentedViewController) {
        [self adWasDismissed];
    } else {
        self.interstitialAd = nil;
        self.presentedViewController = nil;
    }
    
}

- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd
                   willLeaveApplication:(BOOL)willLeave {
    [self.delegate adapterWasClicked: self];
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
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZiAdBannerAdapter alloc] initWithReportingDelegate:reportingDelegate parentAdapter:self options:options];
}

- (BOOL)hasBannerCredentials {
    return YES;
}

- (void)adWasDismissed {
    [self.delegate adapterDidDismissAd:self];
    self.interstitialAd = nil;
    self.presentedViewController = nil;
}

@end
