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

#import "HZHeyzapIncentivizedAd.h"
#import "HZHeyzapInterstitialAd.h"
#import "HZHeyzapVideoAd.h"

/**
 *  This class needs the most work. I should use delegate callbacks to get errors but thats it I think.
 */
@interface HZHeyzapAdapter()

@end

@implementation HZHeyzapAdapter

+ (instancetype)sharedInstance
{
    static HZHeyzapAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZHeyzapAdapter alloc] init];
//        [HeyzapAds start]; // This should probably call into start..
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
            [HZHeyzapInterstitialAd fetchForTag:tag withCompletion:nil];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZHeyzapIncentivizedAd fetchWithCompletion:nil];
            break;
        }
        case HZAdTypeVideo: {
            [HZHeyzapVideoAd fetchForTag:tag withCompletion:nil];
            break;
        }
    }
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (type & HZAdTypeVideo) {
        return [HZHeyzapVideoAd isAvailableForTag:tag];
    } else if (type & HZAdTypeInterstitial) {
        return [HZHeyzapInterstitialAd isAvailableForTag:tag];
    } else  {
        return [HZHeyzapIncentivizedAd isAvailable];
    }
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    switch (type) {
        case HZAdTypeInterstitial: {
            [HZHeyzapInterstitialAd showForTag:tag completion:nil];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZHeyzapIncentivizedAd show];
            break;
        }
        case HZAdTypeVideo: {
            [HZHeyzapVideoAd showForTag:tag completion:nil];
            break;
        }
    }
}

@end
