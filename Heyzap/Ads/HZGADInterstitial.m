//
//  HZGADInterstitial.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZGADInterstitial.h"
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADInterstitial

@dynamic adUnitID;
@dynamic isReady;
@dynamic delegate;

+ (id)alloc
{
    return [NSClassFromString([self hzProxiedClassName]) alloc];
}

+ (NSString *)hzProxiedClassName
{
    return @"GADInterstitial";
}

@end
