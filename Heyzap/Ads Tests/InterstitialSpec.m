//
//  InterstitialSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/14.
//  Copyright 2014 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZInterstitialAdModel.h"


SPEC_BEGIN(InterstitialSpec)

describe(@"HZInterstitialAdModel", ^{
    
    context(@"Initialization", ^{
        it(@"Should initialize with portrait interstitial JSON", ^{
            HZInterstitialAdModel *ad = [[HZInterstitialAdModel alloc] initWithDictionary:[TestJSON portraitInterstitialJSON]];
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
