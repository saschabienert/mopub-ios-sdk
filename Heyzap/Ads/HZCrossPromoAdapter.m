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

- (NSString *)testActivityInstructions {
    return @"When you launch an app using the Heyzap SDK, we register that you've installed that game, and won't show you ads for it. This often causes developers to not receive cross promo ads.\n\nTo work around this, reset your Advertising Identifier from Settings > Privacy > Advertising > Reset Advertising Identfier...";
}


@end
