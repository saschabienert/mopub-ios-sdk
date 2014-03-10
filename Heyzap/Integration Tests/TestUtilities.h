//
//  TestUtilities.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/9/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestUtilities : NSObject

/**
 *  Waits until the return value of the block is true.
 *
 *  @param waitBlock The block to execute until it returns true. Must not be NULL. For convenience, the block is executed on the main queue.
 *  @param timeout The time to wait before raising an exception. Must be >= 0
 */
void waitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout);

/**
 *  If not on the main queue, executes the block on the main queue and waits for it to finish. If on the main queue, just executes the block.
 *
 *  @param block The block to execute. Must not be NULL.
 */
void dispatchSyncMainQueueIfNecessary(void (^block)(void));

@end
