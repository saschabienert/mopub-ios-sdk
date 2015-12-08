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

- (void)zztestCompletingIncentivizedVideo {
//    [self runIncentivizedAndSkip:NO];
}

- (void)testSkippingIncentivizedVideo {
    [self runIncentivizedAndSkip:YES];
}

const int kCrossPromoVideoCreativeID = 6109031;

- (void)runIncentivizedAndSkip:(BOOL)shouldSkip
{
    if (shouldSkip) {
        [HZVideoControlView setUseLargeHideButton:YES];
    }
    [OHHTTPStubs onStubActivation:^(NSURLRequest * _Nonnull request, id<OHHTTPStubsDescriptor>  _Nonnull stub) {
        NSLog(@"Stubbing request: %@",request.URL.path);
    }];
    
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
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path containsString:@"fastclick"];
//        return [request.URL.path isEqualToString:@"assets/ads/fastclick-62c1d38f8e964c75f8de61457fd6dd2d.js"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"fastclick" withExtension:@"js"];
        NSParameterAssert(url);
        return [[OHHTTPStubsResponse alloc] initWithFileURL:url statusCode:200 headers:@{@"content-type":@"application/javascript"}];
    }];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path containsString:@"flat_ios"];
//        return [request.URL.path isEqualToString:@"assets/ads/flat_ios-e54b2fe012a7581343586c20d28138b9.css"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"flat_ios" withExtension:@"css"];
        NSParameterAssert(url);
        return [[OHHTTPStubsResponse alloc] initWithFileURL:url statusCode:200 headers:@{@"content-type":@"text/css"}];
    }];
    
    NSString *const filename = shouldSkip ? @"ten_second_cross_promo_video" : @"three_second_cross_promo_video";
    [OHHTTPStubs stubRequestContainingString:@"930153bd01e935dd75a7f803f7b33f33-h264_android_ld"
                               withVideoFile:filename];
    
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
//        [tester waitForTimeInterval:5];
//        [tester waitForAbsenceOfViewWithAccessibilityLabel:kHZSkipAccessibilityLabel];
        
//        [tester tapScreenAtPoint:CGPointMake(100, 100)];
//        [tester waitForTappableViewWithAccessibilityLabel:kHZSkipAccessibilityLabel];
        NSLog(@"About to tap skip accessibility label");
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
    [HZVideoControlView setUseLargeHideButton:NO];
}

@end
