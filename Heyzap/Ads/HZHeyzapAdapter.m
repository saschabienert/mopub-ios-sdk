//
//  HZHeyzapProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapAdapter.h"
#import "HeyzapAds.h"

@interface HZHeyzapAdapter()

@end

@implementation HZHeyzapAdapter

+ (instancetype)sharedInstance
{
    static HZHeyzapAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZHeyzapAdapter alloc] init];
        [HeyzapAds start];
    });
    return proxy;
}

+ (BOOL)isSDKAvailable
{
    return YES;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeIncentivized;
}

- (void)prefetch
{
    // Heyzap auto-prefetches--no implementation
}

- (BOOL)hasAd
{
    return [HZInterstitialAd isAvailable];
}

- (void)showAd
{
    [HZInterstitialAd show];
}

@end
