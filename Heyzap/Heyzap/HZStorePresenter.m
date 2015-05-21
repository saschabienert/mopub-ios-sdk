//
//  HZStorePresenter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZStorePresenter.h"
#import "HZDevice.h"
#import "HZAdsAPIClient.h"
#import "HZUtils.h"
@import StoreKit;

@interface HZStorePresenter() <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *clickTrackingWebView;

@end

@implementation HZStorePresenter

+ (instancetype) sharedInstance {
    static dispatch_once_t _singletonPredicate;
    static HZStorePresenter *sharedInstance = nil;
    dispatch_once(&_singletonPredicate, ^{
        sharedInstance = [[HZStorePresenter alloc] init];
    });
    
    return sharedInstance;
}

// Completion for 'didOpenAppStore'
- (SKStoreProductViewController *)presentAppStoreForID:(NSNumber *)appStoreID
    presentingViewController:(UIViewController *)viewController
                    delegate:(id<SKStoreProductViewControllerDelegate>)delegate
            useModalAppStore:(BOOL)useModalAppStore
                    clickURL:(NSURL *)clickURL
                impressionID:(NSString *)impressionID
                  completion:(void(^)(BOOL result, NSError *error))completion {
    
    // Override app store ID from the click URL, if applicable.
    NSString *const clickURLAppID = [HZUtils hzQueryDictionaryFromURL:clickURL][@"app_id"];
    if (clickURLAppID && clickURLAppID.intValue) {
        appStoreID = [NSNumber numberWithInt:clickURLAppID.intValue];
    }
    
    if(NSClassFromString(@"SKStoreProductViewController") && appStoreID && useModalAppStore) { // Checks for iOS 6 feature.
        if (clickURL) {
            self.clickTrackingWebView = [[UIWebView alloc] init];
            self.clickTrackingWebView.delegate = self;
            [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:clickURL]];
        }
        
        NSUInteger supportedOrientations = [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: [[UIApplication sharedApplication] keyWindow]];
        BOOL doesNotSupportPortraitOrientation = !((supportedOrientations & UIInterfaceOrientationPortrait) || (supportedOrientations & UIInterfaceOrientationPortraitUpsideDown));
        
        // iOS 7 Bug
        if (![HZDevice hzSystemVersionIsLessThan: @"7.0"] && doesNotSupportPortraitOrientation) {
            [[UIApplication sharedApplication] openURL: clickURL];
            return nil;
        }
        
        SKStoreProductViewController *storeController = [[SKStoreProductViewController alloc] init];
        storeController.delegate = delegate; // productViewControllerDidFinish
        
        // Fixes a bug where, when the presenting view controller is portrait-only on iOS 8 iPads, it presenting the modal app store will cause it to rotate to landscape. Thanks to Arvind of ZeptoLabs for the suggested fix
        // https://app.asana.com/0/12872086712148/18101846589214/f
        if (hziOS8Plus() && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            storeController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        
        static NSString * const kAffiliateToken = @"10l74x";
        
        NSDictionary *productParameters = ({
            NSMutableDictionary *params = [@{ SKStoreProductParameterITunesItemIdentifier :  appStoreID } mutableCopy];
            if (hziOS8Plus()) {
                params[SKStoreProductParameterAffiliateToken] = kAffiliateToken;
            }
            params;
        });
        
        [storeController loadProductWithParameters:productParameters
                                   completionBlock:^(BOOL result, NSError *error) {
            if (!result || error) {
                
                // You can check how often we run into this w/ this Kibana query @message="Error showing SKStoreProductViewController(modal app store)"
                NSString *errorMessage = [NSString stringWithFormat:@"This means someone clicked on the ad but we couldn't show them the modal app store. We fallback to the regular app store if this is the case. If this link https://itunes.apple.com/app/id%@ fails, then we're probably showing an ad for a country the app isn't available in.",appStoreID];
                
                [[HZAdsAPIClient sharedClient] logMessageToHeyzap:@"Error showing SKStoreProductViewController(modal app store)"
                                                            error:error
                                                         userInfo:@{@"Explanation": errorMessage,
                                                                    @"App Store ID":appStoreID,
                                                                    @"Impression ID":impressionID}];
                
                completion ? completion(result, error) : nil;
                [[UIApplication sharedApplication] openURL: clickURL];
            } else {
                completion ? completion(YES, nil) : nil;
                [viewController presentViewController:storeController animated:YES completion:nil];
            }
        }];
        return storeController;
    } else {
        NSError *error = [NSError errorWithDomain:@"heyzap"
                                            code:1
                                        userInfo:@{NSLocalizedDescriptionKey: @"SKStoreProductViewController wasn't available"}];
        completion ? completion(NO, error) : nil;
        [[UIApplication sharedApplication] openURL: clickURL];
        return nil;
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if(url.host &&
       ([url.host rangeOfString:@"itunes.apple"].location != NSNotFound
        || [url.host rangeOfString:@"appstore.com"].location != NSNotFound)) {
        //We've loaded a click URL in the webview, don't redirect to itunes since we are launching
        //the store kit product view
        return NO;
    }
    
    return YES;
}

@end
