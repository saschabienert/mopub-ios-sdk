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
        
        [[[HZAdsManager sharedManager] delegateForAdUnit: self.ad.adUnit] didHideAdWithTag: self.ad.tag];
        
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
        [[[HZAdsManager sharedManager] delegateForAdUnit: self.ad.adUnit] didShowAdWithTag: self.ad.tag];
    }
}

- (void) didClickWithURL: (NSURL *) url {
    
    [[HZMetrics sharedInstance] logMetricsEvent:@"ad-clicked" value:@1 tag:self.ad.tag type:self.ad.adUnit];
    
    if ([self.ad onClick]) {
        [[[HZAdsManager sharedManager] delegateForAdUnit: self.ad.adUnit] didClickAdWithTag: self.ad.tag];
    }

    NSDictionary *queryDictionary = [HZUtils hzQueryDictionaryFromURL: url];
    
    id appID = [queryDictionary objectForKey:@"app_id"];
    if (!appID) {
        appID = [NSString stringWithFormat: @"%i", [self.ad.promotedGamePackage intValue]];
    }
    
    NSURL *clickURL;
    id urlString = [queryDictionary objectForKey:@"click_url"];
    if (urlString) {
        clickURL = [NSURL URLWithString:urlString];
    } else {
        clickURL = self.ad.clickURL;
    }
    
    //try and open StoreKit, otherwise just use market link
    if(NSClassFromString(@"SKStoreProductViewController") && appID && self.ad.useModalAppStore) { // Checks for iOS 6 feature.
        
        if (clickURL != nil) {
            // Ping the tracking url (effectively does nothing if there is no real tracking URL)
            self.clickTrackingWebView = [[UIWebView alloc] initWithFrame: CGRectZero];
    //        [self.view addSubview: self.clickTrackingWebView];
            self.clickTrackingWebView.delegate = self;
            [self.clickTrackingWebView loadRequest: [NSURLRequest requestWithURL: clickURL]];
        }
        
        NSUInteger supportedOrientations = [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: [[UIApplication sharedApplication] keyWindow]];
        BOOL doesNotSupportPortraitOrientation = !((supportedOrientations & UIInterfaceOrientationPortrait) || (supportedOrientations & UIInterfaceOrientationPortraitUpsideDown));
        
        // iOS 7 Bug
        if (![HZDevice hzSystemVersionIsLessThan: @"7.0"] && doesNotSupportPortraitOrientation) {
            [[UIApplication sharedApplication] openURL: clickURL];
            return;
        }
        
        SKStoreProductViewController *storeController = [[SKStoreProductViewController alloc] init];
        storeController.delegate = self; // productViewControllerDidFinish
        
        static NSString * const kAffiliateKey = @"at";
        static NSString * const kAffiliateToken = @"10l74x";
        
        NSDictionary *productParameters = @{ SKStoreProductParameterITunesItemIdentifier :  appID,
                                             kAffiliateKey:kAffiliateToken};
        
        
        
        // WWDC 2012 Session 302: Selling Products with Store Kit does the `presentViewController` step inside the `completionBlock` after checking for the `result`. The downside to this is that we have to wait for that load to finish. As an alternative, I present immediately and if we run into an error, dismiss the ad and fallback to the regular app store.
        
        // Even in the regular Heyzap app, if I open SKStoreProductViewController a bunch of times I get an error about not being able to load StoreKit. There's nothing on the internet to solve this, so I presume there's some kind of rate limiting or XPC (Interprocess Communication; Remote View Controllers) is just generally unreliable.
        // You can check how often we run into this w/ this Kibana query @message="Error showing SKStoreProductViewController(modal app store)"
        [storeController loadProductWithParameters:productParameters completionBlock:^(BOOL result, NSError *error) {
            if (!result || error) {
    
                NSString *errorMessage = [NSString stringWithFormat:@"This means someone clicked on the ad but we couldn't show them the modal app store. We fallback to the regular app store if this is the case. If this link https://itunes.apple.com/app/id%@ fails, then we're probably showing an ad for a country the app isn't available in.",appID];
                
                [[HZAdsAPIClient sharedClient] logMessageToHeyzap:@"Error showing SKStoreProductViewController(modal app store)"
                                                            error:error
                                                         userInfo:@{@"Explanation": errorMessage,
                                                                    @"App Store ID":appID,
                                                                    @"Impression ID":self.ad.impressionID}];
                
                [[UIApplication sharedApplication] openURL: self.ad.clickURL];
                
                [self productViewControllerDidFinish: storeController];
                
            } else {
                [self presentViewController: storeController animated: YES completion:^{
                }];
            }
        }];
        
    } else {
        [[UIApplication sharedApplication] openURL: clickURL];
    }
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
