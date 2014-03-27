//
//  HZDispatch.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZDispatch.h"

@implementation HZDispatch

void hzDispatchSyncMainQueueIfNecessary(void (^block)(void))
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
