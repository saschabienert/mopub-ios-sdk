//
//  HZNativeAdSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/29/14.
//  Copyright 2014 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZNativeAd.h"
#import "HZNativeAd_Private.h"


SPEC_BEGIN(HZNativeAdSpec)

describe(@"HZNativeAd", ^{
    
    context(@"Initialization", ^{
        
        it(@"Should initialize with valid data", ^{
            NSMutableDictionary *nativeAdJSON = [TestJSON nativeAdJSON];
            NSError *error;
            HZNativeAd *ad = [[HZNativeAd alloc] initWithDictionary:nativeAdJSON error:&error];
            [[ad shouldNot] beNil];
            [[error should] beNil];
        });
        it(@"Should succeeed without the description", ^{
            NSMutableDictionary *nativeAdJSON = [TestJSON nativeAdJSON];
            [nativeAdJSON[@"data"] removeObjectForKey:@"description"];
            NSError *error;
            HZNativeAd *ad = [[HZNativeAd alloc] initWithDictionary:nativeAdJSON error:&error];
            [[ad shouldNot] beNil];
            [[error should] beNil];
        });
        
        it(@"Should fail without the game name", ^{
            NSMutableDictionary *nativeAdJSON = [TestJSON nativeAdJSON];
            [nativeAdJSON[@"data"] removeObjectForKey:@"display_name"];
            NSError *error;
            HZNativeAd *ad = [[HZNativeAd alloc] initWithDictionary:nativeAdJSON error:&error];
            [[ad should] beNil];
            [[error shouldNot] beNil];
            [[error.localizedFailureReason shouldNot] beNil];
        });
        it(@"Should fail without the icon_uri", ^{
            NSMutableDictionary *nativeAdJSON = [TestJSON nativeAdJSON];
            [nativeAdJSON[@"data"] removeObjectForKey:@"icon_uri"];
            NSError *error;
            HZNativeAd *ad = [[HZNativeAd alloc] initWithDictionary:nativeAdJSON error:&error];
            [[ad should] beNil];
            [[error shouldNot] beNil];
            [[error.localizedFailureReason shouldNot] beNil];
        });
        
    });
    
});

SPEC_END
