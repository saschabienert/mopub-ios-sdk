//
//  HZNativeAdCollectionSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/29/14.
//  Copyright 2014 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZNativeAdCollection.h"

#import "HZNativeAd.h"
#import "HZNativeAd_Private.h"

#import "HZNativeAdCollection_Private.h"

SPEC_BEGIN(HZNativeAdCollectionSpec)

describe(@"HZNativeAdCollection", ^{
    
    context(@"Initialization", ^{
        it(@"Should return nil when given 0 ads", ^{
            HZNativeAdCollection *coll = [[HZNativeAdCollection alloc] initWithAds:@[]];
            [[coll should] beNil];
        });
        it(@"Should return nil when given nil", ^{
            HZNativeAdCollection *coll = [[HZNativeAdCollection alloc] initWithAds:nil];
            [[coll should] beNil];
        });
        it(@"Should return a collection when given an array of native ads", ^{
            HZNativeAdCollection *coll = [[HZNativeAdCollection alloc] initWithAds:@[[HZNativeAd mock]]];
            [[coll shouldNot] beNil];
        });
    });

});

SPEC_END
