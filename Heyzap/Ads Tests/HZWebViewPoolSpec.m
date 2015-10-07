//
//  HZWebViewPoolSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/24/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZWebViewPool.h"
#import "HZDevice.h"


SPEC_BEGIN(HZWebViewPoolSpec)

describe(@"HZWebViewPool", ^{
    context(@"Pool initialization", ^{
        let(pool, ^{
            return [[HZWebViewPool alloc] init];
        });
        
        it(@"Should start empty", ^{
            [[theValue([pool cachedPools]) should] equal:@0];
        });
        
        // Initializing webviews in tests fails on iOS 7 for some reason
        
        it(@"Should initialize the # of pools we ask for", ^{
            if (hziOS8Plus()) {
                [pool seedWithPools:4];
                [[theValue([pool cachedPools]) should] equal:@4];
            }
        });
        
        it(@"Should have 1 less when we dequeue after seeding", ^{
            if (hziOS8Plus()) {
                [pool seedWithPools:2];
                [pool checkoutPool];
                [[theValue([pool cachedPools]) should] equal:@1];
            }
        });
        
        it(@"Should give back a web view even when empty", ^{
            if (hziOS8Plus()) {
                [[[pool checkoutPool] shouldNot] beNil];
            }
        });
        
        it(@"Should grow in size when we give it back a pool", ^{
            if (hziOS8Plus()) {
                const NSUInteger currentSize = [pool cachedPools];
                [pool returnWebView:[[UIWebView alloc] init]];
                [[theValue([pool cachedPools]) should] equal:@(currentSize + 1)];
            }
        });
    });
});

SPEC_END
