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
#import "HZVideoView.h"
#import "OHHTTPStubsResponse+JSON.h"
#import "HZAdVideoViewController.h"

@implementation TestHeyzapVideo

- (void)testCompletingIncentivizedVideo {
    NSLog(@"Running complete incent test");
    [self runIncentivizedAndSkip:NO];
}

- (void)testSkippingIncentivizedVideo {
    [self runIncentivizedAndSkip:YES];
}

const int kCrossPromoVideoCreativeID = 6109031;

- (void)runIncentivizedAndSkip:(BOOL)shouldSkip
{
    [self stubStartAndMediate];
    
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
    
    [self stubWebViewContent];
    [self stubHeyzapEventEndpoints];
    
    
    NSString *const filename = shouldSkip ? @"ten_second_cross_promo_video_no_audio" : @"three_second_no_audio";
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
    [system waitForNotificationName:HZMediationDidShowAdNotification object:nil whileExecutingBlock:^{
        [HZIncentivizedAd showForTag:tag];
    }];
    NSLog(@"Showing video");
    [MKTVerify(mockDelegate) didShowAdWithTag:tag];
    
    // Skip
    if (shouldSkip) {
        [system runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
            HZAdVideoViewController *videoController = [self findVideoViewController];
            if (videoController) {
                [videoController skipVideo];
                return KIFTestStepResultSuccess;
            } else {
                NSParameterAssert(error);
                *error = [NSError errorWithDomain:@"Didn't find HZAdVideoViewController" code:1 userInfo:nil];
                return KIFTestStepResultFailure;
            }
        }];
    }
    
    // Wait a bit to allow the close button to appear.
    [tester waitForTimeInterval:3];
    
    // Close
    [self closeHeyzapWebView];
//    [tester waitForViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
//    [tester tapViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
//    [tester waitForAbsenceOfViewWithAccessibilityLabel:kCloseButtonAccessibilityLabel];
    
    [tester waitForTimeInterval:2];
    
    [MKTVerify(mockDelegate) didHideAdWithTag:tag];
    if (shouldSkip) {
        [MKTVerify(mockDelegate) didFailToCompleteAdWithTag:tag];
    } else {
        [MKTVerify(mockDelegate) didCompleteAdWithTag:tag];
    }
}

- (HZAdVideoViewController *)findVideoViewController {
    UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    id presented = root.presentedViewController;
    if ([presented isKindOfClass:[HZAdVideoViewController class]]) {
        return presented;
    } else {
        return nil;
    }
}

@end
