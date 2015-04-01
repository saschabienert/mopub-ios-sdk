//
//  HZAdapterDelegate.m
//  Heyzap
//
//  Created by Mike Urbach on 3/31/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZAdapterDelegate.h"
#import "HeyzapMediation.h"

#pragma clang diagnostic ignored "-Wprotocol"
@implementation HZAdapterDelegate

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [HZAdapterDelegate instanceMethodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.adapter respondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:self.adapter];
    }
    
    [[HeyzapMediation sharedInstance] forwardInvocation:invocation forNetwork:self.adapter.network];
}

@end
