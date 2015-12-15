//
//  TestFacebookInterstitial.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/14/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "TestFacebookInterstitial.h"

#import "TestFacebookInterstitial.h"
#import "HZFetchOptions.h"
#import "HeyzapMediation.h"
@import WebKit;

@implementation TestFacebookInterstitial

- (void)testShowingAndCloseFacebookInterstitial
{
    [self stubStartAndMediate];
    
    // Mocking
    id<HZAdsDelegate> mockDelegate = mockProtocol(@protocol(HZAdsDelegate));
    [HZInterstitialAd setDelegate:mockDelegate];
    
    // Fetch
    NSString *const tag = NSStringFromSelector(_cmd);
    NSDictionary *const useFacebookParams = @{ @"network": HZNetworkFacebook };
    
    HZFetchOptions *fetchOptions = [HZFetchOptions new];
    fetchOptions.requestingAdType = HZAdTypeInterstitial;
    fetchOptions.tag = tag;
    fetchOptions.additionalParameters = useFacebookParams;
    
    [system waitForNotificationName:HZMediationDidReceiveAdNotification object:nil whileExecutingBlock:^{
        [[HeyzapMediation sharedInstance] fetchWithOptions:fetchOptions];
    }];
    
    [MKTVerify(mockDelegate) didReceiveAdWithTag:tag];
    
    // Show
    HZShowOptions *showOpts = [[HZShowOptions alloc] init];
    showOpts.tag = tag;
    [[HeyzapMediation sharedInstance] showForAdType:HZAdTypeInterstitial
                                   additionalParams:useFacebookParams
                                            options:showOpts];
    
    [tester waitForTimeInterval:3];
    [MKTVerify(mockDelegate) didShowAdWithTag:tag];
    
    [system runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
        WKWebView *webView = [self findViewOfClass:[WKWebView class]];
        if (webView) {
            [webView evaluateJavaScript:@"document.getElementById(\"fbAdCloseLink\").click()" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Error evaluating Javascript to close Facebook ad: %@",error);
                }
            }];
            return KIFTestStepResultSuccess;
        } else {
            return KIFTestStepResultFailure;
        }
    }];
    
    [tester waitForTimeInterval:3];
    
    [MKTVerify(mockDelegate) didHideAdWithTag:tag];
}



@end