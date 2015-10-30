//
//  TestHeyzapVideo.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/15/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "TestHeyzapVideo.h"
#import "HZFetchOptions.h"
#import "HeyzapMediation.h"
#import "HZVideoControlView.h"
#import "OHHTTPStubsResponse+JSON.h"

@implementation TestHeyzapVideo

- (void)testCompletingIncentivizedVideo {
    [self runIncentivizedAndSkip:NO];
}

- (void)testSkippingIncentivizedVideo {
    [self runIncentivizedAndSkip:YES];
}

const int kCrossPromoVideoCreativeID = 6109031;

- (void)runIncentivizedAndSkip:(BOOL)shouldSkip
{
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:[TestJSON jsonForResource:@"start"]];
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:[TestJSON jsonForResource:@"mediate"]];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path isEqualToString:@"/in_game_api/ads/fetch_ad"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSDictionary *queryDictionary = [HZUtils hzQueryDictionaryFromURL: request.URL];
        if ([queryDictionary[@"auction_type"] isEqualToString:@"cross_promo"]) {
            return [OHHTTPStubsResponse responseWithJSONObject:[TestJSON jsonForResource:@"cross_promo_video"]
                                                    statusCode:200
                                                       headers:nil];
        } else {
            return [OHHTTPStubsResponse responseWithJSONObject:@{}
                                                    statusCode:400
                                                       headers:nil];
        }
    }];
    
    [OHHTTPStubs stubRequestContainingString:@"930153bd01e935dd75a7f803f7b33f33-h264_android_ld"
                               withVideoFile:@"three_second_cross_promo_video"];
    
    // Mocking
    id<HZIncentivizedAdDelegate> mockDelegate = mockProtocol(@protocol(HZIncentivizedAdDelegate));
    [HZIncentivizedAd setDelegate:mockDelegate];
    
    // Fetch
    NSString *const tag = [NSStringFromSelector(_cmd) lowercaseString];
    [HZIncentivizedAd setCreativeID:6109031];
    
    HZFetchOptions *const fetchOptions = [HZFetchOptions new];
    fetchOptions.requestingAdType = HZAdTypeIncentivized;
    fetchOptions.tag = tag;
    fetchOptions.additionalParameters = @{ @"network": @"heyzap_cross_promo" };
    
    [system waitForNotificationName:HZMediationDidReceiveAdNotification object:nil whileExecutingBlock:^{
        [[HeyzapMediation sharedInstance] fetchWithOptions:fetchOptions];
    }];
    
    [MKTVerify(mockDelegate) didReceiveAdWithTag:tag];
    
    // Show
    [HZIncentivizedAd showForTag:tag];
    [tester waitForViewWithAccessibilityLabel:kHZSkipAccessibilityLabel];
    [MKTVerify(mockDelegate) didShowAdWithTag:tag];
    
    // Skip
    if (shouldSkip) {
        [tester tapViewWithAccessibilityLabel:kHZSkipAccessibilityLabel];
    }
    
    // Close
    [tester waitForViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
    
    [MKTVerify(mockDelegate) didHideAdWithTag:tag];
    if (shouldSkip) {
        [MKTVerify(mockDelegate) didFailToCompleteAdWithTag:tag];
    } else {
        [MKTVerify(mockDelegate) didCompleteAdWithTag:tag];
    }
}

@end
