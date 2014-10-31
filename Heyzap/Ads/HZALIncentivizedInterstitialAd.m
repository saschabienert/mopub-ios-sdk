//
//  HZALIncentivizedInterstitialAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZALIncentivizedInterstitialAd.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZALIncentivizedInterstitialAd

@dynamic adDisplayDelegate;
@dynamic adVideoPlaybackDelegate;
@dynamic readyForDisplay;

+ (NSString *)hzProxiedClassName
{
    return @"ALIncentivizedInterstitialAd";
}

@end
