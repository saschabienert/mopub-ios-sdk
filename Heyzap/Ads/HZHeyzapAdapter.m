//
//  HZHeyzapProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapAdapter.h"
#import "HeyzapAds.h"
#import "HZMediationConstants.h"
#import "HZInterstitialAd.h"
#import "HZIncentivizedAd.h"
#import "HZVideoAd.h"

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

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return YES;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeIncentivized;
}

+ (NSString *)name
{
    return kHZAdapterHeyzap;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    switch (type) {
        case HZAdTypeInterstitial: {
            [HZInterstitialAd fetchForTag:tag];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZIncentivizedAd fetch];
            break;
        }
        case HZAdTypeVideo: {
            [HZVideoAd fetchForTag:tag];
            break;
        }
    }
}

- (void)prefetch
{
    // Heyzap auto-prefetches--no implementation
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (type & HZAdTypeVideo) {
        return [HZVideoAd isAvailableForTag:tag];
    } else if (type & HZAdTypeInterstitial) {
        return [HZInterstitialAd isAvailableForTag:tag];
    } else  {
        return [HZIncentivizedAd isAvailable];
    }
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    switch (type) {
        case HZAdTypeInterstitial: {
            [HZInterstitialAd showForTag:tag];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZIncentivizedAd show];
            break;
        }
        case HZAdTypeVideo: {
            [HZVideoAd showForTag:tag];
            break;
        }
    }
}

- (void)showAd
{
    [HZInterstitialAd show];
}

@end
