//
//  HZEnums.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZEnums.h"
#import "HZMediationConstants.h"
#import "HZCrossPromoAdapter.h"
#import "HZHeyzapAdapter.h"

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
            return [HZCrossPromoAdapter name];
            break;
        }
        case HZAuctionTypeMixed: {
            return [HZHeyzapAdapter name];
            break;
        }
        case HZAuctionTypeMonetization: {
            return [HZHeyzapAdapter name];
            break;
        }
    }
}

NSString * NSStringFromHZFetchableCreativeType(HZFetchableCreativeType fetchableCreativeType) {
    switch (fetchableCreativeType) {
        case HZFetchableCreativeTypeStatic: {
            return @"HZFetchableCreativeTypeStatic";
        }
        case HZFetchableCreativeTypeVideo: {
            return @"HZFetchableCreativeTypeVideo";
        }
        case HZFetchableCreativeTypeNative: {
            return @"HZFetchableCreativeTypeNative";
        }
    }
}

@end
