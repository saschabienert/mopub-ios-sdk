//
//  HZMediate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/15/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Object handling requests to mediate, including retrying and caching logic.
 */
@interface HZMediateRequester : NSObject

@property (nonatomic, readonly) NSDictionary *latestMediate;
@property (nonatomic, readonly) NSDictionary *latestMediateParams;

- (void)start;
- (void)refreshMediate;

@end
