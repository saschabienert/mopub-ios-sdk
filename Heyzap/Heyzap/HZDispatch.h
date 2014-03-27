//
//  HZDispatch.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZDispatch : NSObject

void hzDispatchSyncMainQueueIfNecessary(void (^block)(void));

@end
