//
//  HZALAdService.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZALAdSize;
@protocol HZALAdLoadDelegate;

@interface HZALAdService : HZClassProxy

- (BOOL)hasPreloadedAdOfSize:(HZALAdSize *)adSize;

- (void)loadNextAd:(HZALAdSize *)adSize andNotify:(id<HZALAdLoadDelegate>)delegate;
- (void)preloadAdOfSize:(HZALAdSize *)adSize;

@end
