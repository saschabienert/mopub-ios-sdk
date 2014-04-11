//
//  DelegateProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/2/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "DelegateProxy.h"
#import "TestDelegate.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@interface DelegateProxy()

@property (nonatomic, strong) TestDelegate *delegateSelectorSwallower;

@end

@implementation DelegateProxy

- (id)init
{
    _delegateSelectorSwallower = [[TestDelegate alloc] init];
    return self;
}

// (later, after testing is done)
// This will just check if the given delegate responds to a selector, and if so then send it the message, otherwise the TestDelegate eats it
-  (id)forwardingTargetForSelector:(SEL)aSelector
{
    NSAssert([NSThread isMainThread], @"Callbacks must be on the main thread");
    NSLog(@"Delegate received selector: %@",NSStringFromSelector(aSelector));
    if ([self.forwardingTarget respondsToSelector:aSelector]) {
        return self.forwardingTarget;
    } else {
        return self.delegateSelectorSwallower;
    }
}

@end
