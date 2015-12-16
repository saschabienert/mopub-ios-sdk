//
//  HZAdType.h
//  Heyzap
//
//  Created by Mike Urbach on 3/31/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

// This is a bitmasked parameter, but with the exception of the `supportedAdFormats` method, almost everything else should treat it as just an enum.
typedef NS_OPTIONS(NSUInteger, HZAdType) {
    HZAdTypeInterstitial = 1 << 0,
    HZAdTypeVideo = 1 << 1,
    HZAdTypeIncentivized = 1 << 2,
    // placeholder for moreapps
    HZAdTypeBanner = 1 << 4,
    HZAdTypeNative = 1 << 5,
};

NSString * NSStringFromAdType(HZAdType type);
HZAdType hzAdTypeFromString(NSString *adUnit);

BOOL hzCanShowConcurrentlyWithOtherAds(const HZAdType adType);