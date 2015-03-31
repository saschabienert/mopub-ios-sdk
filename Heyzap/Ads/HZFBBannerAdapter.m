//
//  HZFBBannerAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZFBBannerAdapter.h"
#import "HZFBAdView.h"
#import "HZMediationConstants.h"
#import "HZBannerAdOptions_Private.h"

@interface HZFBBannerAdapter()

@property (nonatomic, strong) HZFBAdView *adView;
@property (nonatomic) BOOL isLoaded;

@end

@implementation HZFBBannerAdapter

- (instancetype)initWithAdUnitId:(NSString *)adUnitId options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        
        _adView = [[HZFBAdView alloc] initWithPlacementID:adUnitId adSize:options.internalFacebookAdSize rootViewController:options.presentingViewController];
        
        _adView.delegate = self;
        [_adView loadAd];
    }
    return self;
}

- (BOOL)isAvailable {
    return self.isLoaded;
}

#pragma mark - HBFBAdViewDelegate Protocol
- (void)adViewDidClick:(HZFBAdView *)adView {
    // Report click
    [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
    [self.bannerInteractionDelegate userDidClick];
    [self.bannerInteractionDelegate willPresentModalView];
}
- (void)adViewDidFinishHandlingClick:(HZFBAdView *)adView {
    [self.bannerInteractionDelegate didDismissModalView];
}
- (void)adViewDidLoad:(HZFBAdView *)adView {
    // if on screen, then register impression
    // else monitor view for superview
    self.isLoaded = YES;
    [self.bannerInteractionDelegate didReceiveAd];
}
- (void)adView:(HZFBAdView *)adView didFailWithError:(NSError *)error {
    self.isLoaded = NO;
    self.lastError = error;
    [self.bannerInteractionDelegate didFailToReceiveAd:error];
}
- (void)adViewWillLogImpression:(HZFBAdView *)adView {
    [self.bannerReportingDelegate bannerAdapter:self hadImpressionForSession:self.session];
}

- (UIView *)mediatedBanner {
    return (UIView *)self.adView;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"FBAdViewDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

@end
