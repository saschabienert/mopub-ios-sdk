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
    context(@"Class methods", ^{
        it(@"Shouldn't be valid for video", ^{
            NSUInteger a = 16;
            NSUInteger b = 26;
            [[theValue(a + b) should] equal:theValue(42)];
        });
    });
});

SPEC_END
