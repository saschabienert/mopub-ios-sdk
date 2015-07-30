//
//  HZInterstitialVideoConfigSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZInterstitialVideoConfig.h"


SPEC_BEGIN(HZInterstitialVideoConfigSpec)

describe(@"HZInterstitialVideoConfig", ^{
    it(@"Parses correctly", ^{
        NSDictionary *params = @{
                                 @"interstitial_video_interval": @1000000,
                                 @"interstitial_video_enabled": @YES,
                                 };
        HZInterstitialVideoConfig *config = [[HZInterstitialVideoConfig alloc] initWithDictionary:params];
        
        [[theValue(config.interstitialVideoIntervalMillis) should] equal:@1000000];
        [[theValue(config.interstitialVideoEnabled) should] equal:@YES];
    });
    
    it(@"Defaults to enabled", ^{
        HZInterstitialVideoConfig *config = [[HZInterstitialVideoConfig alloc] initWithDictionary:@{}];
        [[theValue(config.interstitialVideoEnabled) should] equal:@YES];
    });
});

SPEC_END
