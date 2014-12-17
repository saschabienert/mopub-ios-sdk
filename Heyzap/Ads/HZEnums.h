//
//  HZEnums.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZEnums : NSObject

/**
 *  The auction type for a given fetch request. Mediation specifies either Monetization or Cross Promo only (this allows it to treat Cross Promo as just-another-ad-network, putting it at the front of the waterfall). Regular Heyzap just uses 'mixed', which means both Xpromo + monetization (this is also default serverside).
 */
typedef NS_ENUM(NSUInteger, HZAuctionType) {
    /**
     *  Both monetizing + xpromo ads
     */
    HZAuctionTypeMixed,
    /**
     *  Monetizing ads only
     */
    HZAuctionTypeMonetization,
    /**
     *  Xpromo only
     */
    HZAuctionTypeCrossPromo,
};


/**
 *  Converts an HZAuctionType value into the string value that the server uses.
 *
 *  @param auctionType The auction type
 *
 *  @return A string that the server will recognize for an auction_type param.
 */
NSString * NSStringFromHZAuctionType(HZAuctionType auctionType);

/**
 *  Converts an HZAuctionType value into the string value of the Heyzap adapter for that auction type. i.e. HZAuctionTypeCrossPromo -> heyzap_cross_promo
 *
 *  @param auctionType The auction type
 *
 *  @return Either heyzap or heyzap_cross_promo, depending on auctionType
 */
NSString * HeyzapAdapterFromHZAuctionType(HZAuctionType auctionType);

@end
