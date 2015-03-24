//
//  HZiAdBannerAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZiAdBannerAdapter.h"
@import iAd;

@interface HZiAdBannerAdapter() <ADBannerViewDelegate>

@property (nonatomic, strong) ADBannerView *banner;

@end

@implementation HZiAdBannerAdapter

- (instancetype)init {
    self = [super init];
    if (self) {
        _banner = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        _banner.delegate = self;
    }
    return self;
}

- (NSString *)networkName {
    return @"iads"; // TODO, return constant.
}
- (UIView *)mediatedBanner {
    return self.banner;
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner {
    // Ignored
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [self.reportingDelegate didReceiveAd];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    self.lastError = error;
    [self.reportingDelegate didFailToReceiveAd:error];
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    [self.reportingDelegate userDidClick];
    
    if (willLeave) {
        [self.reportingDelegate willLeaveApplication];
    } else {
        [self.reportingDelegate willPresentModalView];
    }
    
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    [self.reportingDelegate didDismissModalView];
}

- (BOOL)isAvailable {
    return self.banner.isBannerLoaded;
}

@end
