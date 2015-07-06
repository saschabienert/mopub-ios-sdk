//
//  HZHeyzapExchangeBannerAdapter.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/29/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeBannerAdapter.h"
#import "HZMRAIDView.h"
#import "HZHeyzapExchangeBannerClient.h"
#import "HeyzapMediation.h"
#import "HZHeyzapExchangeAdapter.h"

@interface HZHeyzapExchangeBannerAdapter()<HZMRAIDViewDelegate, HZHeyzapExchangeBannerClientDelegate>
@property (nonatomic) HZMRAIDView *bannerView;
@property (nonatomic) HZBannerAdOptions *options;
@property (nonatomic) HZHeyzapExchangeBannerClient *client;

@property (nonatomic) BOOL isLoaded;

@end


@implementation HZHeyzapExchangeBannerAdapter

- (instancetype) initWithAdUnitID:(NSString *)adUnitID options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter {
    
    self = [super init];
    if(self){
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        _options = options;
        
        _client = [[HZHeyzapExchangeBannerClient alloc] init];
        [_client fetchWithOptions:options delegate:self];
    }
    
    return self;
}


- (UIView *)mediatedBanner {
    return self.bannerView;
}

- (BOOL)isAvailable {
    return self.isLoaded;
}

- (NSNumber *) adScore{
    if(![self isAvailable]){
        return nil;
    }
    
    return self.client.adScore;
}


#pragma mark - HZHeyzapExchangeBannerClientDelegate

- (void) fetchSuccessWithClient:(HZHeyzapExchangeBannerClient *)client banner:(HZMRAIDView *)banner {}

- (void) fetchFailedWithClient:(HZHeyzapExchangeBannerClient *)client {
    self.lastError = [NSError errorWithDomain:@"com.heyzap.ads.exchange.banners" code:1 userInfo:@{@"error":@"fetch_failed"}];
    [self mraidViewAdFailed:nil];
}

- (void) bannerInteractionWillLeaveApplication:(BOOL)willLeaveApplication{
    [self.bannerReportingDelegate bannerAdapter:self wasClickedWithEventReporter:self.eventReporter];
    [self.bannerInteractionDelegate userDidClick];
    if(willLeaveApplication){
        [self.bannerInteractionDelegate willLeaveApplication];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: [HZHeyzapExchangeAdapter name]];
    }
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerClick forNetwork: [HZHeyzapExchangeAdapter name]];
}

- (void)bannerReady:(HZMRAIDView *)banner {
    self.bannerView = banner;
    self.isLoaded = YES;
    self.lastError = nil;
    [self.bannerInteractionDelegate didReceiveAd];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerLoaded forNetwork: [HZHeyzapExchangeAdapter name]];
}

// sent when html is invalid for ad
- (void)bannerFailed {
    self.bannerView = nil;
    self.isLoaded = NO;
    self.lastError = [NSError errorWithDomain:@"com.heyzap.ads.exchange.banners" code:1 userInfo:@{@"error":@"fetch_failed_bad_ad"}];
    [self.bannerInteractionDelegate didFailToReceiveAd:nil];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerFetchFailed forNetwork: [HZHeyzapExchangeAdapter name]];
}

- (void)bannerWillShow {
    [self.bannerReportingDelegate bannerAdapter:self hadImpressionWithEventReporter:self.eventReporter];
}

- (void)bannerDidClose {
    self.isLoaded = NO;
    self.bannerView = nil;
    self.lastError = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerDismiss forNetwork: [HZHeyzapExchangeAdapter name]];
}

@end