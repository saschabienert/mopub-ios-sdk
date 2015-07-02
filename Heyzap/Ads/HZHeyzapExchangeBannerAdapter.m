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

@property (nonatomic) UIWebView *clickTrackingWebView;

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
        _client.delegate = self;
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


#pragma mark - HZHeyzapExchangeBannerClientDelegate

- (void) fetchSuccessWithClient:(HZHeyzapExchangeBannerClient *)client banner:(HZMRAIDView *)banner {}
- (void) fetchFailedWithClient:(HZHeyzapExchangeBannerClient *)client {
    [self mraidViewAdFailed:nil];
}

- (void) bannerInteractionWillLeaveApplication:(BOOL)willLeaveApplication{
    [self.bannerInteractionDelegate userDidClick];
    if(willLeaveApplication){
        [self.bannerInteractionDelegate willLeaveApplication];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: [HZHeyzapExchangeAdapter name]];
    }
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerClick forNetwork: [HZHeyzapExchangeAdapter name]];
}


#pragma mark - HZMRAIDViewDelegate (banners)

- (void)mraidViewAdReady:(HZMRAIDView *)mraidView {
    self.bannerView = mraidView;
    self.isLoaded = YES;
    [self.bannerInteractionDelegate didReceiveAd];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerLoaded forNetwork: [HZHeyzapExchangeAdapter name]];
}

- (void)mraidViewAdFailed:(HZMRAIDView *)mraidView {
    self.bannerView = nil;
    self.isLoaded = NO;
    [self.bannerInteractionDelegate didFailToReceiveAd:nil];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerFetchFailed forNetwork: [HZHeyzapExchangeAdapter name]];
}

- (void)mraidViewWillExpand:(HZMRAIDView *)mraidView{
    [self.bannerReportingDelegate bannerAdapter:self hadImpressionForSession:self.session];
}

- (void)mraidViewDidClose:(HZMRAIDView *)mraidView {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerDismiss forNetwork: [HZHeyzapExchangeAdapter name]];
}

- (void)mraidViewNavigate:(HZMRAIDView *)mraidView withURL:(NSURL *)url {
    self.clickTrackingWebView = [[UIWebView alloc] init];
    [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.bannerReportingDelegate bannerAdapter:self wasClickedForSession:self.session];
    [self.bannerInteractionDelegate userDidClick];
    [self.bannerInteractionDelegate willLeaveApplication];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackBannerClick forNetwork: [HZHeyzapExchangeAdapter name]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackLeaveApplication forNetwork: [HZHeyzapExchangeAdapter name]];
}

@end