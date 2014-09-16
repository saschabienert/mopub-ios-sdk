    //
//  HZAdController.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdViewController.h"
#import "HZDevice.h"
#import <StoreKit/StoreKit.h>
#import "HZUtils.h"
#import "HZAdsManager.h"
#import "HZAdsAPIClient.h"
#import "HZMetrics.h"
#import "HZStorePresenter.h"

@interface HZAdViewController()<SKStoreProductViewControllerDelegate, UIWebViewDelegate>

@property (nonatomic) UIWebView *clickTrackingWebView;
@property (nonatomic) UIWindow *originalKeyWindow;
@property (nonatomic) UIViewController *storeController;

@property (nonatomic) BOOL statusBarHidden;

@end

@implementation HZAdViewController

- (id) initWithAd:(HZAdModel *)ad {
    self = [super init];
    if (self) {
        self.ad = ad;
    }
    
    return self;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) dealloc {
    if (self.clickTrackingWebView != nil) {
        [self.clickTrackingWebView loadHTMLString: @"" baseURL: nil];
        [self.clickTrackingWebView stopLoading];
        self.clickTrackingWebView.delegate = nil;
        [self.clickTrackingWebView removeFromSuperview];
//        
//        [self.clickTrackingWebView HZcleanForDealloc];
    }
    
    self.clickTrackingWebView = nil;
}

- (void) show {
    
    self.statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    // ** Steal UIWindow
    // The order of this is important because we are hiding the
    // status bar, and if the root controller is set before this happens,
    // the controller's coordinate space assumes the status bar is visible.
    self.originalKeyWindow = [[UIApplication sharedApplication] keyWindow];
    self.window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    
    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    
    [self.window setBackgroundColor: [UIColor clearColor]];
    [self.window makeKeyAndVisible];
    [self.window setRootViewController: self];
    [[HZMetrics sharedInstance] logTimeSinceShowAdFor:@"show_ad_time_till_ad_is_displayed" tag:self.ad.tag type:self.ad.adUnit];
}

- (void) hide {
    [[HZMetrics sharedInstance] removeAdForTag:self.ad.tag type:self.ad.adUnit];
    
    [UIView animateWithDuration: 0.15 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.layer.opacity = 0.0f;
    } completion:^(BOOL finished) {
        [self.originalKeyWindow makeKeyAndVisible];
        [self.window setRootViewController: nil];
        self.window = nil;
        
        [self.ad cleanup];
        
        [[HZAdsManager sharedManager] setActiveController: nil];

        // Revert back to old status bar state
        [[UIApplication sharedApplication] setStatusBarHidden: self.statusBarHidden];
        
        //    Fix for iOS 8 not rotating the view/window correctly.
        //    https://devforums.apple.com/thread/240069?tstart=15
        //    http://openradar.appspot.com/radar?id=4933288959410176
        if (self.ad.enableWindowBoundsReset) {
            self.originalKeyWindow.frame = [UIScreen mainScreen].bounds;
        }
        
        [[[HZAdsManager sharedManager] delegateForAdUnit: self.ad.adUnit] didHideAdWithTag: self.ad.tag];
        [HZAdsManager postNotificationName:kHeyzapDidHideAdNotification infoProvider:self.ad];
        
        
        if ([self.ad.adUnit isEqualToString: @"interstitial"]) {
            if (![[HZAdsManager sharedManager] isOptionEnabled: HZAdOptionsDisableAutoPrefetching]) {
                [HZInterstitialAd fetchForTag: self.ad.tag];
            }
        }
    }];
}

- (void) didClickHeyzapInstall {
    
}

static int totalImpressions = 0;

- (void) didImpression {
    totalImpressions++;
    [[HZMetrics sharedInstance] logMetricsEvent:@"nth_ad"
                                          value:@(totalImpressions)
                                            tag:self.ad.tag
                                           type:self.ad.adUnit];
    [[HZMetrics sharedInstance] logTimeSinceFetchFor:@"time_from_fetch_to_impression"
                                                 tag:self.ad.tag
                                                type:self.ad.adUnit];
    
    
    if ([self.ad onImpression]) {
        [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didShowAdWithTag:self.ad.tag];
        [HZAdsManager postNotificationName:kHeyzapDidShowAdNotitification infoProvider:self.ad];
    }
}

- (void) didClickWithURL: (NSURL *) url {
    
    [[HZMetrics sharedInstance] logMetricsEvent:@"ad-clicked" value:@1 tag:self.ad.tag type:self.ad.adUnit];
    
    if ([self.ad onClick]) {
        [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didClickAdWithTag:self.ad.tag];
        [HZAdsManager postNotificationName:kHeyzapDidClickAdNotification infoProvider:self.ad];
    }

    NSDictionary *queryDictionary = [HZUtils hzQueryDictionaryFromURL: url];
    
    NSURL *clickURL;
    id urlString = [queryDictionary objectForKey:@"click_url"];
    if (urlString) {
        clickURL = [NSURL URLWithString:urlString];
    } else {
        clickURL = self.ad.clickURL;
    }
    
    
    [[HZStorePresenter sharedInstance] presentAppStoreForID:self.ad.promotedGamePackage
                                   presentingViewController:self
                                                   delegate:self
                                           useModalAppStore:self.ad.useModalAppStore
                                                   clickURL:clickURL
                                               impressionID:self.ad.impressionID
                                                 completion:nil];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissModalViewControllerAnimated: YES];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if(url.host && [url.host rangeOfString:@"itunes.apple"].location != NSNotFound){
        //We've loaded a click URL in the webview, don't redirect to itunes since we are launching
        //the store kit product view
        
        [HZLog debug: @"(POSTBACK COMPLETE)"];
        
        return NO;
    }
    
    return YES;
}

-  (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

#pragma mark - Utility

- (BOOL) applicationSupportsLandscape {
    if ([HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
        return YES;
    } else {
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: self.window] & UIInterfaceOrientationMaskLandscape;
    }
}


@end
