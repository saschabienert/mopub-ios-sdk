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

- (BOOL)respondsToSelector:(SEL)selector {
    return [self.adapter respondsToSelector:selector] || [[[HeyzapMediation sharedInstance] getDelegateForNetwork:self.adapter.network] respondsToSelector:selector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [self.adapter.class instanceMethodSignatureForSelector:selector];
    if (!signature) {
        signature = [[[[HeyzapMediation sharedInstance] getDelegateForNetwork:self.adapter.network] class] instanceMethodSignatureForSelector:selector];
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL selector = [invocation selector];

    if ([self.adapter respondsToSelector:selector]) {
        [invocation invokeWithTarget:self.adapter];
    }
    
    id delegate = [[HeyzapMediation sharedInstance] getDelegateForNetwork:self.adapter.network];
    if ([delegate respondsToSelector:selector]) {
        [invocation invokeWithTarget:delegate];
    }
}

@end
