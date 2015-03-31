//
//  HZGADBannerView.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZGADBannerView.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADBannerView

@dynamic adUnitID;
@dynamic rootViewController;
@dynamic adSize;
@dynamic delegate;

+ (NSString *)hzProxiedClassName {
    return @"GADBannerView";
}

@end
