//
//  HZDispatch.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZDispatch : NSObject

/**
 *  Waits until the return value from waitBlock is true, or it times out.
 *
 *  @param waitBlock      The block to run repeatedly until it returns YES.
 *  @param timeout        The time to wait before returning NO.
 *
 *  @return YES if successful, NO if not in the timeout.
 */
BOOL hzWaitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout);;

@end
