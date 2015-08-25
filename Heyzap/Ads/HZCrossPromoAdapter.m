//
//  HZCrossPromoAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZCrossPromoAdapter.h"
#import "HZHeyzapIncentivizedAd.h"
#import "HZHeyzapInterstitialAd.h"
#import "HZHeyzapVideoAd.h"
#import "HZAdsManager.h"
#import "HZMediationConstants.h"

@interface HZCrossPromoAdapter()

@end

@implementation HZCrossPromoAdapter

+ (instancetype)sharedAdapter
{
    static HZCrossPromoAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZCrossPromoAdapter alloc] init];
    });
    return adapter;
}

+ (NSString *)name
{
    return HZNetworkCrossPromo;
}

+ (NSString *)humanizedName
{
    return kHZAdapterCrossPromoHumanized;
}

- (HZAuctionType)auctionType {
    return HZAuctionTypeCrossPromo;
}


@end
