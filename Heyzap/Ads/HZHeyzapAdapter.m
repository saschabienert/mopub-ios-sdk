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

#import "HZAdsManager.h"

@interface HZHeyzapAdapter()

@end

@implementation HZHeyzapAdapter

+ (instancetype)sharedAdapter
{
    static HZHeyzapAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZHeyzapAdapter alloc] init];
    });
    return proxy;
}

+ (NSString *)name
{
    return HZNetworkHeyzap;
}

+ (NSString *)humanizedName
{
    return kHZAdapterHeyzapHumanized;
}

- (HZAuctionType)auctionType {
    return HZAuctionTypeMonetization;
}


@end
