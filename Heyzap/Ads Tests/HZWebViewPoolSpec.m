//
//  HZWebViewPoolSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/24/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZWebViewPool.h"


SPEC_BEGIN(HZWebViewPoolSpec)

describe(@"HZWebViewPool", ^{
    context(@"Pool initialization", ^{
        let(pool, ^{
            return [[HZWebViewPool alloc] init];
        });
        
        it(@"Should start empty", ^{
            [[theValue([pool cachedPools]) should] equal:@0];
        });
        
        it(@"Should initialize the # of pools we ask for", ^{
            [pool seedWithPools:4];
            [[theValue([pool cachedPools]) should] equal:@4];
        });
        
        it(@"Should have 1 less when we dequeue after seeding", ^{
            [pool seedWithPools:2];
            [pool checkoutPool];
            [[theValue([pool cachedPools]) should] equal:@1];
        });
        
        it(@"Should give back a web view even when empty", ^{
            [[[pool checkoutPool] shouldNot] beNil];
        });
        
        it(@"Should grow in size when we give it back a pool", ^{
            const NSUInteger currentSize = [pool cachedPools];
            [pool returnWebView:[[UIWebView alloc] init]];
            [[theValue([pool cachedPools]) should] equal:@(currentSize + 1)];
        });
    });
});

SPEC_END
