//
//  HZiAdBannerAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZiAdBannerAdapter.h"
#import "HZMediationConstants.h"
#import "HeyzapMediation.h"

@import iAd;

@interface HZiAdBannerAdapter() <ADBannerViewDelegate>

@property (nonatomic, strong) ADBannerView *banner;
@property (nonatomic) BOOL waitingToBeAddedToScreen;

@end

@implementation HZiAdBannerAdapter

- (instancetype)initWithReportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter options:(HZBannerAdOptions *)options {
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        
        _banner = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        _banner.delegate = self;
    }
    return self;
}

- (UIView *)mediatedBanner {
    return self.banner;
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner {
    // Ignored
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    if (banner.superview) {
        [self.bannerReportingDelegate bannerAdapter:self hadImpressionForSession:self.session];
    } else {
        self.waitingToBeAddedToScreen = YES;
    }
    
    [self.bannerInteractionDelegate didReceiveAd];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerLoaded forNetwork: HZNetworkIAd];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    self.lastError = error;
    [self.bannerInteractionDelegate didFailToReceiveAd:error];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerFetchFailed forNetwork: HZNetworkIAd];
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
    [self.bannerInteractionDelegate userDidClick];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerClick forNetwork: HZNetworkIAd];
    
    if (willLeave) {
        [self.bannerInteractionDelegate willLeaveApplication];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: HZNetworkIAd];
    } else {
        [self.bannerInteractionDelegate willPresentModalView];
    }
    
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    [self.bannerInteractionDelegate didDismissModalView];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerDismiss forNetwork: HZNetworkIAd];
}

- (BOOL)isAvailable {
    return self.banner.isBannerLoaded;
}

- (void)bannerWasAddedToView {
    if (self.waitingToBeAddedToScreen) {
        [self.bannerReportingDelegate bannerAdapter:self hadImpressionForSession:self.session];
        self.waitingToBeAddedToScreen = NO;
    }
}

@end
