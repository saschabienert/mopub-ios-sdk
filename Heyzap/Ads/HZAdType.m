//
//  HZAdType.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/21/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZAdType.h"

NSString * NSStringFromAdType(HZAdType type)
{
    switch (type) {
        case HZAdTypeInterstitial: {
            return @"interstitial";
            break;
        }
        case HZAdTypeIncentivized: {
            return @"incentivized";
            break;
        }
        case HZAdTypeVideo: {
            return @"video";
            break;
        }
        case HZAdTypeBanner: {
            return @"banner";
        }
    }
}

HZAdType hzAdTypeFromString(NSString *adUnit) {
    if ([adUnit isEqualToString:@"incentivized"]) {
        return HZAdTypeIncentivized;
    } else if ([adUnit isEqualToString:@"video"]) {
        return HZAdTypeVideo;
    } else {
        return HZAdTypeInterstitial;
    }
}

// This will be true for native ads as well, when those are added.
BOOL hzCanShowConcurrentlyWithOtherAds(const HZAdType adType) {
    switch (adType) {
        case HZAdTypeBanner: {
            return YES;
        }
        case HZAdTypeInterstitial:
        case HZAdTypeVideo:
        case HZAdTypeIncentivized: {
            return NO;
        }
    }
}