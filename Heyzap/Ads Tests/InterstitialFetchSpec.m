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
        // Bundle Identifier is coming back nil because [NSBundle mainBundle] returns nil (bundleForClass works)
        [[NSBundle mainBundle] stub:@selector(bundleIdentifier) andReturn:@"Heyzap.Ads-Tests"];
        [HZAdsManager stub:@selector(runInitialTasks)]; // ProcessInfo, install reporting, etc. causes problems
        [[HZDevice currentDevice] stub:@selector(HZadvertisingIdentifier) andReturn:@"1234-5432-5653-4543"];
    });
    
    afterAll(^{
        [OHHTTPStubs removeAllStubs];
    });
    
    context(@"When doing a fetch", ^{
        it(@"should succeed with known good data", ^{
            
            [OHHTTPStubs stubRequestContainingString:@"fetch_ad" withJSON:[TestJSON portraitInterstitialJSON]];
            
            HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:@[@"interstitial", @"full_screen_interstitial", @"video", @"interstitial_video"] adUnit:@"interstitial" tag:nil auctionType:HZAuctionTypeMonetization andAdditionalParams:nil];
            
            __block HZAdModel *blockModel;
            [[HZAdsFetchManager sharedManager] fetch:request withCompletion:^(HZAdModel *model, NSString *tag, NSError *error) {
                blockModel = model;
            }];
            [[expectFutureValue(blockModel) shouldEventually] beNonNil];
            
            
            
        });
    });

});

SPEC_END