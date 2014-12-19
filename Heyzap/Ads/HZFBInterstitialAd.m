//
//  HZFBInterstitialAd.m
//  Heyzap
//
//  Created by David Stumm on 12/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZFBInterstitialAd.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZFBInterstitialAd

@dynamic delegate;
@dynamic placementID;

+ (NSString *)hzProxiedClassName
{
    return @"FBInterstitialAd";
}

@end
