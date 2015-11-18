//
//  HZIMBanner.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZIMBanner.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZIMBanner

@dynamic delegate;
@dynamic refreshInterval;
@dynamic keywords;
@dynamic extras;
@dynamic placementId;
@dynamic transitionAnimation;

+ (NSString *)hzProxiedClassName {
    return @"IMBanner";
}

@end
