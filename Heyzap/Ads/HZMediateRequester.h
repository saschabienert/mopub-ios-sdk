//
//  HZMediate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/15/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZCachingService;

@protocol HZMediateRequesterDelegate <NSObject>

- (void)requesterUpdatedMediate;

@end

/**
 *  Object handling requests to mediate, including retrying and caching logic.
 */
@interface HZMediateRequester : NSObject

- (instancetype)initWithDelegate:(id<HZMediateRequesterDelegate>)delegate cachingService:(HZCachingService *)cachingService;

@property (nonatomic, readonly) NSDictionary *latestMediate;
@property (nonatomic, readonly) NSDictionary *latestMediateParams;

- (void)start;
- (void)refreshMediate;

@end
