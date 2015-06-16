//
//  HZMediate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/15/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZMediateRequester : NSObject

@property (nonatomic, readonly) NSDictionary *latestMediate;
@property (nonatomic, readonly) NSDictionary *latestMediateParams;

- (void)start;
- (void)refreshMediate;

// Get the latest /mediate
// Fallback to cache
//

// Using stale data: Cons
// Gives us less guarantees than mediate-per-show
//

// Using stale data: Pros
// Can show ads on app-launch. This is a well-known use case (requires 3rd party ad networks caching ads, which it seems they do).

// What to do if we don't have a /mediate:
// Super edge case, except at app launch. Doesn't really matter. Either fail immediately, have a timeout for /mediate, or use stale data.

@end
