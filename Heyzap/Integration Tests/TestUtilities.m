//
//  TestUtilities.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/9/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "TestUtilities.h"
#import "SLLogger.h"
#import "HZDispatch.h"

@implementation TestUtilities

void waitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout)
{
    NSCParameterAssert(waitBlock);
    NSCParameterAssert(timeout > 0);
    
    NSTimeInterval timeWaited = 0;
    while (true) {
        
        __block BOOL waitCondition = NO;
        ensureMainQueue(^{
            waitCondition = waitBlock();
        });
        
        if (waitCondition) {
            break;
        } else if (timeWaited >= timeout) {
            [NSThread sleepForTimeInterval:2];
            NSCAssert(@"Timeout exception", @"Hit timeout waiting for an event");
        } else {
            static const NSTimeInterval sleepInterval = 0.5;
            [NSThread sleepForTimeInterval:sleepInterval];
            timeWaited += sleepInterval;
        }
    }
}

@end
