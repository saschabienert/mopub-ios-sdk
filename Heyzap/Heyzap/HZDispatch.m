//
//  HZDispatch.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZDispatch.h"

@implementation HZDispatch


BOOL hzWaitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout) {
    return hzWaitUntilInterval(0.2, waitBlock, timeout);
}

BOOL hzWaitUntilInterval(const NSTimeInterval interval, BOOL (^waitBlock)(void), const NSTimeInterval timeout) {
    NSCParameterAssert(waitBlock);
    NSCParameterAssert(timeout > 0);
    
    NSTimeInterval timeWaited = 0;
    while (true) {
        
        __block BOOL waitCondition = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            waitCondition = waitBlock();
        });
        
        if (waitCondition) {
            return YES;
        } else if (timeWaited >= timeout) {
            return NO;
        } else {
            [NSThread sleepForTimeInterval:interval];
            timeWaited += interval;
        }
    }
}

void ensureMainQueue(void (^block)(void))
{
    NSCParameterAssert(block);
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

@end
