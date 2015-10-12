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

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

@implementation TestHeyzapInterstitial

const int kCrossPortraitFullscreenCrossPromoCreativeID = 6136623;
NSString * const kCloseButtonAccessibilityLabel = @"X";

- (void)testShowingAndClosingHeyzapInterstitial
{
    // Mocking
    id<HZAdsDelegate> mockDelegate = mockProtocol(@protocol(HZAdsDelegate));
    [HZInterstitialAd setDelegate:mockDelegate];
    
    // Fetch
    NSString *const tag = [NSStringFromSelector(_cmd) lowercaseString];
    [HZInterstitialAd setCreativeID:kCrossPortraitFullscreenCrossPromoCreativeID];
    HZFetchOptions *fetchOptions = [HZFetchOptions new];
    fetchOptions.requestingAdType = HZAdTypeInterstitial;
    fetchOptions.tag = tag;
    fetchOptions.additionalParameters = @{ @"network": @"heyzap" };
    
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
