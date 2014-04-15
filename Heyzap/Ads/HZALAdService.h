//
//  HZALAdService.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZALAdSize;

@interface HZALAdService : HZClassProxy

- (BOOL)hasPreloadedAdOfSize:(HZALAdSize *)adSize;

@end
