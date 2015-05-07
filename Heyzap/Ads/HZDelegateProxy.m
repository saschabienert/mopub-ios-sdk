//
//  DelegateProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/2/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZDelegateProxy.h"
#import "HZTestDelegate.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@interface HZDelegateProxy()

@property (nonatomic, strong) HZTestDelegate *delegateSelectorSwallower;

@end

@implementation HZDelegateProxy

- (id)init
{
    _delegateSelectorSwallower = [[HZTestDelegate alloc] init];
    return self;
}

-  (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (![NSThread isMainThread]) {
        NSLog(@"Callbacks must be sent on the main thread.");
        HZAssert([NSThread isMainThread], @"Callbacks must be on the main thread");
    }
    if ([self.forwardingTarget respondsToSelector:aSelector]) {
        return self.forwardingTarget;
    } else {
        return self.delegateSelectorSwallower;
    }
}

@end