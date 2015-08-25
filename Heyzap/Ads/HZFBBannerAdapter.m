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
#import "HeyzapMediation.h"

#import "HZFBAdSettings.h"

@interface HZFBBannerAdapter()

@property (nonatomic, strong) HZFBAdView *adView;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) BOOL reportedMostRecentImpressionAsFirstImpression;

@end

@implementation HZFBBannerAdapter

- (instancetype)initWithAdUnitId:(NSString *)adUnitId options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter {
    HZAssert(adUnitId, @"Need a Banner Placement ID by this point");
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        
        HZDLog(@"Initializing Facebook Audience Network banner with placement ID: %@",adUnitId);
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
    [self.bannerReportingDelegate bannerAdapter:self wasClickedWithEventReporter:self.eventReporter];
    [self.bannerInteractionDelegate userDidClick];
    [self.bannerInteractionDelegate willPresentModalView];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerClick forNetwork: HZNetworkFacebook];
}

- (void)adViewDidFinishHandlingClick:(HZFBAdView *)adView {
    [self.bannerInteractionDelegate didDismissModalView];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerHide forNetwork: HZNetworkFacebook];
}
- (void)adViewDidLoad:(HZFBAdView *)adView {
    // if on screen, then register impression
    // else monitor view for superview
    self.isLoaded = YES;
    [self.bannerInteractionDelegate didReceiveAd];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerLoaded forNetwork: HZNetworkFacebook];
}
- (void)adView:(HZFBAdView *)adView didFailWithError:(NSError *)error {
    self.isLoaded = NO;
    self.lastError = error;
    [self.bannerInteractionDelegate didFailToReceiveAd:error];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerFetchFailed forNetwork: HZNetworkFacebook];
}
- (void)adViewWillLogImpression:(HZFBAdView *)adView {
    if (self.reportedMostRecentImpressionAsFirstImpression) {
        self.reportedMostRecentImpressionAsFirstImpression = NO;
    } else {
        [self.bannerReportingDelegate bannerAdapter:self hadReloadedImpressionWithEventReporter:self.eventReporter];
    }
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"banner-logging_impression" forNetwork: HZNetworkFacebook];
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

- (void) bannerWasAddedToView {
    self.reportedMostRecentImpressionAsFirstImpression = YES;
    [self.bannerReportingDelegate bannerAdapter:self hadInitialImpressionWithEventReporter:self.eventReporter];
}

@end
