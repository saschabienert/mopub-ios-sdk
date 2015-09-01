//
//  InterstitialSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/14.
//  Copyright 2014 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZInterstitialAdModel.h"
#import "HZDevice.h"


SPEC_BEGIN(InterstitialSpec)

describe(@"HZInterstitialAdModel", ^{
    
    beforeAll(^{
        // Workaround a bug where, when running tests from the command line, iOS doesn't find the advertising identifier.
        [[HZDevice currentDevice] stub:@selector(HZadvertisingIdentifier) andReturn:@"1234-5432-5653-4543"];
    });
    
    context(@"Initialization", ^{
        it(@"Should initialize with portrait interstitial JSON", ^{
            HZInterstitialAdModel *ad = [[HZInterstitialAdModel alloc] initWithDictionary:[TestJSON portraitInterstitialJSON] fetchableCreativeType:HZFetchableCreativeTypeStatic auctionType:HZAuctionTypeMonetization];
            [[ad shouldNot] beNil];
        });
        
//        it(@"should fail without ad_html", ^{
//            NSMutableDictionary *json = [TestJSON portraitInterstitialJSON];
//            [json removeObjectForKey:@"ad_html"];
//            HZInterstitialAdModel *ad = [[HZInterstitialAdModel alloc] initWithDictionary:json];
//            [[ad should] beNil];
//        });
    });
    
});

SPEC_END
