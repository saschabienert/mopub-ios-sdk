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
        [self.bannerReportingDelegate bannerAdapter:self hadImpressionForSession:self.session];
    } else {
        self.waitingToBeAddedToScreen = YES;
    }
}
- (void)adView:(HZGADBannerView *)view didFailToReceiveAdWithError:(HZGADRequestError *)error {
    self.lastError = (NSError *)error;
    [self.bannerInteractionDelegate didFailToReceiveAd:(NSError *)error];
}
- (void)adViewWillPresentScreen:(HZGADBannerView *)adView {
    [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
    [self.bannerInteractionDelegate userDidClick];
    [self.bannerInteractionDelegate willPresentModalView];
}
- (void)adViewWillDismissScreen:(HZGADBannerView *)adView {
    // Not reporting this because other FAN doesn't also report it
    // (And its pretty much covered by `didDismissScreen`)
}
- (void)adViewDidDismissScreen:(HZGADBannerView *)adView {
    [self.bannerInteractionDelegate didDismissModalView];
}
- (void)adViewWillLeaveApplication:(HZGADBannerView *)adView {
    [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
    [self.bannerInteractionDelegate userDidClick];
    [self.bannerInteractionDelegate willLeaveApplication];
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
        [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
        self.waitingToBeAddedToScreen = NO;
    }
}

@end
