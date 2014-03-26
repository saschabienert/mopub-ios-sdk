//
//  HZHeyzapProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapProxy.h"
#import "HeyzapAds.h"

@interface HZHeyzapProxy()

@end

@implementation HZHeyzapProxy

+ (instancetype)sharedInstance
{
    static HZHeyzapProxy *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZHeyzapProxy alloc] init];
        [HeyzapAds start];
    });
    return proxy;
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
