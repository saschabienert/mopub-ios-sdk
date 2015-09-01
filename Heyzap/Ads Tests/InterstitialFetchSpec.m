//
//  InterstitialFetchSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/8/14.
//  Copyright 2014 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "OHHTTPStubs.h"
#import "OHHTTPStubsResponse+JSON.h"
#import "HZInterstitialAd.h"
#import "HZAdFetchRequest.h"
#import "HZAdsFetchManager.h"
#import "HZUtils.h"
#import "HZAdsManager.h"
#import "HZDevice.h"

@interface HZAdsManager(Testing)

+ (void)runInitialTasks;

@end

SPEC_BEGIN(InterstitialFetchSpec)

describe(@"InterstitialFetch", ^{
    
    beforeAll(^{
        [HZAdsManager stub:@selector(runInitialTasks)]; // ProcessInfo, install reporting, etc. causes problems
    });
    
    afterAll(^{
        [OHHTTPStubs removeAllStubs];
    });
    
    context(@"When doing a fetch", ^{
        it(@"should succeed with known good data", ^{
            
            // Initializing webviews in tests fails on iOS 7 for some reason
            if (hziOS8Plus()) {
                [OHHTTPStubs stubRequestContainingString:@"fetch_ad" withJSON:[TestJSON portraitInterstitialJSON]];
                
                HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithFetchableCreativeType:HZFetchableCreativeTypeStatic tag:nil auctionType:HZAuctionTypeMonetization andAdditionalParams:nil];
                
                __block HZAdModel *blockModel;
                [[HZAdsFetchManager sharedManager] fetch:request withCompletion:^(HZAdModel *model, NSError *error) {
                    blockModel = model;
                }];
                [[expectFutureValue(blockModel) hzShouldEventuallyAfterDelay] beNonNil];
            }
        });
    });

});

SPEC_END
