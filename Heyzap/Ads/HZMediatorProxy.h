//
//  HZMediatorProtocol.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HZMediatorProxy <NSObject>

+ (instancetype)sharedInstance;

- (void)prefetch;

- (BOOL)hasAd;

- (void)showAd;

// Prefetch method needs the tag and geo (geo for chartboost).
// Or just store geo on chartboost class. That's easier.

/**
 *  Proxies should record their lastError, from e.g. delegate callbacks.
 */
@property (nonatomic, strong) NSError *lastError;

@end