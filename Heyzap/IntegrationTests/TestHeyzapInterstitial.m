//
//  TestAppTest.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/9/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "TestHeyzapInterstitial.h"
#import <KIF/KIF.h>
#import "SDKTestAppViewController.h"
#import "HeyzapAds.h"

#import "HeyzapMediation.h"
#import "HZFetchOptions.h"
#import "HZInterstitialAd.h"
#import "IntegrationTestConfig.h"
#import "TestJSON.h"
#import "OHHTTPStubs+Heyzap.h"
#import "OHHTTPStubsResponse+JSON.h"
#import "HZUtils.h"

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

@implementation TestHeyzapInterstitial

const int kCrossPromoPortraitFullscreenCreativeID = 6136623;


- (void)testShowingAndClosingHeyzapInterstitial
{
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:[TestJSON jsonForResource:@"start"]];
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:[TestJSON jsonForResource:@"mediate"]];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path isEqualToString:@"/in_game_api/ads/fetch_ad"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSDictionary *queryDictionary = [HZUtils hzQueryDictionaryFromURL: request.URL];
        if ([queryDictionary[@"auction_type"] isEqualToString:@"cross_promo"]) {
            return [OHHTTPStubsResponse responseWithJSONObject:[TestJSON jsonForResource:@"cross_promo_static"]
                                                    statusCode:200
                                                       headers:nil];
        } else {
            return [OHHTTPStubsResponse responseWithJSONObject:@{}
                                                    statusCode:400
                                                       headers:nil];
        }
    }];
    
    // Mocking
    id<HZAdsDelegate> mockDelegate = mockProtocol(@protocol(HZAdsDelegate));
    [HZInterstitialAd setDelegate:mockDelegate];
    
    // Fetch
    NSString *const tag = [NSStringFromSelector(_cmd) lowercaseString];
    [HZInterstitialAd setCreativeID:kCrossPromoPortraitFullscreenCreativeID];
    HZFetchOptions *fetchOptions = [HZFetchOptions new];
    fetchOptions.requestingAdType = HZAdTypeInterstitial;
    fetchOptions.tag = tag;
    fetchOptions.additionalParameters = @{ @"network": @"heyzap_cross_promo" };
    
    [system waitForNotificationName:HZMediationDidReceiveAdNotification object:nil whileExecutingBlock:^{
        [[HeyzapMediation sharedInstance] fetchWithOptions:fetchOptions];
    }];
    
    [MKTVerify(mockDelegate) didReceiveAdWithTag:tag];
    
    // Show
    [HZInterstitialAd showForTag:tag];
    [tester waitForViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
    [MKTVerify(mockDelegate) didShowAdWithTag:tag];
    
    // Hide
    [tester tapViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
    [MKTVerify(mockDelegate) didHideAdWithTag:tag];
    
}

@end
