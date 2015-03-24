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

- (instancetype)initWithAdUnitId:(NSString *)adUnitId options:(HZBannerAdOptions *)options {
    self = [super init];
    if (self) {
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
    [self.reportingDelegate userDidClick];
    [self.reportingDelegate willPresentModalView];
}
- (void)adViewDidFinishHandlingClick:(HZFBAdView *)adView {
    [self.reportingDelegate didDismissModalView];
}
- (void)adViewDidLoad:(HZFBAdView *)adView {
    NSLog(@"Facebook loaded a banner!");
    self.isLoaded = YES;
    [self.reportingDelegate didReceiveAd];
}
- (void)adView:(HZFBAdView *)adView didFailWithError:(NSError *)error {
    self.isLoaded = NO;
    self.lastError = error;
    [self.reportingDelegate didFailToReceiveAd:error];
}
- (void)adViewWillLogImpression:(HZFBAdView *)adView {
    
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

- (NSString *)networkName {
    return kHZAdapterFacebook;
}

@end
