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

+ (instancetype)sharedInstance
{
    static HZCrossPromoAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZCrossPromoAdapter alloc] init];
        [[HZAdsManager sharedManager] onStart];
    });
    return adapter;
}

+ (NSString *)name
{
    return kHZAdapterCrossPromo;
}

- (HZAuctionType)auctionType {
    return HZAuctionTypeCrossPromo;
}


@end