//
//  HZiAdBannerAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZiAdBannerAdapter.h"
#import "HZUnityAbstractAdapter.h"
#import "HZMediationConstants.h"
@import iAd;

@interface HZiAdBannerAdapter() <ADBannerViewDelegate>

@property (nonatomic, strong) ADBannerView *banner;

@end

@implementation HZiAdBannerAdapter

- (instancetype)initWithReportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter options:(HZBannerAdOptions *)options {
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        
        _banner = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        _banner.delegate = self;
        
        const CGSize sizeThatFits = [_banner sizeThatFits:options.presentingViewController.view.bounds.size];
        CGRect frame = _banner.frame;
        frame.size = sizeThatFits;
        _banner.frame = frame;
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
        [self startMonitoringForImpression];
    }
    
    [self.bannerInteractionDelegate didReceiveAd];
    [HZUnityAbstractAdapter sendMessage:@"banner-loaded" fromNetwork:kHZAdapteriAd];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    self.lastError = error;
    [self.bannerInteractionDelegate didFailToReceiveAd:error];
    [HZUnityAbstractAdapter sendMessage:@"banner-fetch_failed" fromNetwork:kHZAdapteriAd];
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
    [self.bannerInteractionDelegate userDidClick];
    [HZUnityAbstractAdapter sendMessage:@"banner-click" fromNetwork:kHZAdapteriAd];
    
    if (willLeave) {
        [self.bannerInteractionDelegate willLeaveApplication];
    } else {
        [self.bannerInteractionDelegate willPresentModalView];
    }
    
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    [self.bannerInteractionDelegate didDismissModalView];
    [HZUnityAbstractAdapter sendMessage:@"banner-hide" fromNetwork:kHZAdapteriAd];
}

- (BOOL)isAvailable {
    return self.banner.isBannerLoaded;
}

@end
