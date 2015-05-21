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
#import "HZStorePresenter.h"
#import "HZEnums.h"

@interface HZAdViewController()<SKStoreProductViewControllerDelegate, UIWebViewDelegate>

@property (nonatomic) UIWebView *clickTrackingWebView;
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
    }
    
    self.clickTrackingWebView = nil;
}

- (void) show {
    [self showWithOptions:nil];
}

- (void) showWithOptions:(HZShowOptions *)options {
    
    self.statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    if (!options) {
        options = [HZShowOptions new];
    }

    if (!options.viewController) {
        NSLog(@"Heyzap requires a root view controller to display an ad. Set the `rootViewController` property of [UIApplication sharedApplication].keyWindow to fix this error. If you have any trouble doing this, contact support@heyzap.com");
        
        NSError *const error = [NSError errorWithDomain:@"Heyzap" code:10 userInfo:@{NSLocalizedFailureReasonErrorKey:@"There was no root view controller to display the ad."}];
        [[[HZAdsManager sharedManager] delegateForAdUnit: self.ad.adUnit] didFailToShowAdWithTag:self.ad.tag andError:error];
        [HZAdsManager postNotificationName:kHeyzapDidFailToShowAdNotification infoProvider:self.ad];
        return;
    }

    [options.viewController presentViewController:self animated:NO completion:nil];

    [[UIApplication sharedApplication] setStatusBarHidden: YES];
}

- (void) hide {    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self.ad cleanup];
    
    // Revert back to old status bar state
    [[UIApplication sharedApplication] setStatusBarHidden: self.statusBarHidden];
    
    [[[HZAdsManager sharedManager] delegateForAdUnit: self.ad.adUnit] didHideAdWithTag: self.ad.tag];
    [HZAdsManager postNotificationName:kHeyzapDidHideAdNotification infoProvider:self.ad];
    
    
    if ([self.ad.adUnit isEqualToString: @"interstitial"]) {
        if (![[HZAdsManager sharedManager] isOptionEnabled: HZAdOptionsDisableAutoPrefetching]) {
            [HZInterstitialAd fetchForTag: self.ad.tag];
        }
    }
}

- (void) didClickHeyzapInstall {
    
}

- (void) didImpression {
    if ([self.ad onImpression]) {
        [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didShowAdWithTag:self.ad.tag];
        [HZAdsManager postNotificationName:kHeyzapDidShowAdNotitification infoProvider:self.ad];
    }
}

- (void) didClickWithURL: (NSURL *) url {
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
                                                 completion: ^(BOOL result, NSError *error) {
                                                     
                                                 }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissModalViewControllerAnimated: YES];
    
    [self applicationDidEnterForeground: nil];
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
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: keyWindow] & UIInterfaceOrientationMaskLandscape;
    }
}

- (void) applicationDidEnterForeground: (id) notification {
    
}


@end
