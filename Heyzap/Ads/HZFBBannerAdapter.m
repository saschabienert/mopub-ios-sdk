//
//  HZFBBannerAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZFBBannerAdapter.h"
#import "HZFBAdView.h"

@interface HZFBBannerAdapter()

@property (nonatomic, strong) HZFBAdView *adView;

@end

@implementation HZFBBannerAdapter

- (instancetype)initWithHZFBAdView:(HZFBAdView *)adView {
    NSParameterAssert(adView);
    self = [super init];
    if (self) {
        _adView = adView;
        [_adView loadAd];
    }
    return self;
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
    [self.reportingDelegate didReceiveAd];
}
- (void)adView:(HZFBAdView *)adView didFailWithError:(NSError *)error {
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

@end
