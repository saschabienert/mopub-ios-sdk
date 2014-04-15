//
//  HZALInterstitialAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZALInterstitialAd.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZALInterstitialAd

@dynamic adLoadDelegate;
@dynamic adDisplayDelegate;

+ (NSString *)hzProxiedClassName
{
    return @"ALInterstitialAd";
}

@end
