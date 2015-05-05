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

// https://gist.github.com/maicki/7622108
dispatch_source_t hzCreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}


@end
