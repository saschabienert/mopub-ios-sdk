//
//  HZEnums.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZEnums.h"
#import "HZMediationConstants.h"

@implementation HZEnums

NSString * NSStringFromHZAuctionType(HZAuctionType auctionType) {
    switch (auctionType) {
        case HZAuctionTypeCrossPromo: {
            return @"cross_promo";
            break;
        }
        case HZAuctionTypeMixed: {
            return @"mixed";
            break;
        }
        case HZAuctionTypeMonetization: {
            return @"monetization";
            break;
        }
    }
}

NSString * HeyzapAdapterFromHZAuctionType(HZAuctionType auctionType) {
    switch (auctionType) {
        case HZAuctionTypeCrossPromo: {
            return kHZAdapterCrossPromo;
            break;
        }
        case HZAuctionTypeMixed: {
            return kHZAdapterHeyzap;
            break;
        }
        case HZAuctionTypeMonetization: {
            return kHZAdapterHeyzap;
            break;
        }
    }
}

@end
