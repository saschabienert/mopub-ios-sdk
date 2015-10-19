//
//  HZKIFTestCase.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/15/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZKIFTestCase.h"
#import "IntegrationTestConfig.h"
#import "OHHTTPStubs+Heyzap.h"

@implementation HZKIFTestCase

NSString * const kCloseButtonAccessibilityLabel = @"X";

- (void)beforeEach {
    [super beforeEach];
    
    NSLog(@"HTTP stubbing is: %i",[IntegrationTestConfig sharedConfig].shouldStubHTTPRequests);
    [OHHTTPStubs setEnabled:[IntegrationTestConfig sharedConfig].shouldStubHTTPRequests];
}

- (void)afterEach {
    [super afterEach];
    
    [OHHTTPStubs removeAllStubs];
    
    [HZInterstitialAd setCreativeID:0];
    [HZVideoAd setCreativeID:0];
    [HZIncentivizedAd setCreativeID:0];
}

@end
