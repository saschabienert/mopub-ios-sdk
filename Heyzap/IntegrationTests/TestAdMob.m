//
//  TestAdMob.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/14/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "TestAdMob.h"

#import "TestAdMob.h"
#import "HZFetchOptions.h"
#import "HeyzapMediation.h"

@implementation TestAdMob

NSString * const kAdMobCloseAccessibilityLabel = @"Close Advertisement";

- (void)testAdMobStatic {
    [self runAdMobForAdType:HZAdTypeInterstitial];
}

- (void)testAdMobVideo {
    [self runAdMobForAdType:HZAdTypeVideo];
}

- (void)runAdMobForAdType:(HZAdType)adType
{
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:[TestJSON jsonForResource:@"start"]];
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:[TestJSON jsonForResource:@"mediate"]];
    
    // Mocking
    id<HZAdsDelegate> mockDelegate = mockProtocol(@protocol(HZAdsDelegate));
    Class c = [[HeyzapMediation sharedInstance] classForAdType:adType];
    [c setDelegate:mockDelegate];
    
    // Fetch
    NSString *const tag = [NSStringFromSelector(_cmd) lowercaseString];
    NSDictionary *const useAdMobParams = @{ @"network": HZNetworkAdMob };;
    
    
    
    HZFetchOptions *fetchOptions = [HZFetchOptions new];
    fetchOptions.requestingAdType = adType;
    fetchOptions.tag = tag;
    fetchOptions.additionalParameters = useAdMobParams;
    
    [system waitForNotificationName:HZMediationDidReceiveAdNotification object:nil whileExecutingBlock:^{
        [[HeyzapMediation sharedInstance] fetchWithOptions:fetchOptions];
    }];
    
    [MKTVerify(mockDelegate) didReceiveAdWithTag:tag];
    
    // Show
    HZShowOptions *showOpts = [[HZShowOptions alloc] init];
    showOpts.tag = tag;
    [[HeyzapMediation sharedInstance] showForAdType:adType
                                   additionalParams:useAdMobParams
                                            options:showOpts];
    
    [tester waitForViewWithAccessibilityLabel:kAdMobCloseAccessibilityLabel];
    
    [MKTVerify(mockDelegate) didShowAdWithTag:tag];
    [MKTVerify(mockDelegate) willStartAudio];
    
    [tester tapViewWithAccessibilityLabel:kAdMobCloseAccessibilityLabel];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:kAdMobCloseAccessibilityLabel];
    
    [MKTVerify(mockDelegate) didFinishAudio];
    [MKTVerify(mockDelegate) didHideAdWithTag:tag];
}

@end
