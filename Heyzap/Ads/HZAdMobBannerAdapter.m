//
//  HZAdMobBannerAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZAdMobBannerAdapter.h"
#import "HZGADBannerView.h"
#import "HZMediationConstants.h"
#import "HZBannerAdOptions.h"
#import "HZBannerAdOptions_Private.h"
#import "HeyzapAds.h"
#import "HeyzapMediation.h"
#import "HZAdMobAdapter.h"

@interface HZAdMobBannerAdapter() <HZGADBannerViewDelegate>

@property (nonatomic, strong) HZGADBannerView *banner;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) BOOL waitingToBeAddedToScreen;

@end

@implementation HZAdMobBannerAdapter

- (instancetype)initWithAdUnitID:(NSString *)adUnitID options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        
        _banner = [[HZGADBannerView alloc] initWithAdSize:options.internalAdMobSize];
        _banner.adUnitID = adUnitID;
        _banner.rootViewController = options.presentingViewController;
        _banner.delegate = self;
        [_banner loadRequest:nil];
    }
    return self;
}

- (UIView *)mediatedBanner {
    return (UIView *) self.banner;
}

- (void)adViewDidReceiveAd:(HZGADBannerView *)view {
    self.isLoaded = YES;
    [self.bannerInteractionDelegate didReceiveAd];
    
    UIView *bannerView = (UIView *)self.banner;
    if (bannerView.superview) {
        [self.bannerReportingDelegate bannerAdapter:self hadImpressionWithEventReporter:self.eventReporter];
    } else {
        self.waitingToBeAddedToScreen = YES;
    }
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerLoaded forNetwork: [HZAdMobAdapter name]];
}
- (void)adView:(HZGADBannerView *)view didFailToReceiveAdWithError:(HZGADRequestError *)error {
    self.lastError = (NSError *)error;
    [self.bannerInteractionDelegate didFailToReceiveAd:(NSError *)error];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerFetchFailed forNetwork: [HZAdMobAdapter name]];
}
- (void)adViewWillPresentScreen:(HZGADBannerView *)adView {
    [self.bannerReportingDelegate bannerAdapter:self wasClickedWithEventReporter:self.eventReporter];
    [self.bannerInteractionDelegate userDidClick];
    [self.bannerInteractionDelegate willPresentModalView];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerClick forNetwork: [HZAdMobAdapter name]];
}
- (void)adViewWillDismissScreen:(HZGADBannerView *)adView {
    // Not reporting this because other FAN doesn't also report it
    // (And its pretty much covered by `didDismissScreen`)
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerDismiss forNetwork: [HZAdMobAdapter name]];
}
- (void)adViewDidDismissScreen:(HZGADBannerView *)adView {
    [self.bannerInteractionDelegate didDismissModalView];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerHide forNetwork: [HZAdMobAdapter name]];
}
- (void)adViewWillLeaveApplication:(HZGADBannerView *)adView {
    [self.bannerReportingDelegate bannerAdapter:self wasClickedWithEventReporter:self.eventReporter];
    [self.bannerInteractionDelegate userDidClick];
    [self.bannerInteractionDelegate willLeaveApplication];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: [HZAdMobAdapter name]];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"GADBannerViewDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (BOOL)isAvailable {
    return self.isLoaded;
}

- (void)bannerWasAddedToView {
    if (self.waitingToBeAddedToScreen) {
        [self.bannerReportingDelegate bannerAdapter:self hadImpressionWithEventReporter:self.eventReporter];
        self.waitingToBeAddedToScreen = NO;
    }
}

@end
