//
//  HZAdLibrary.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HZAdModel;

@interface HZAdLibrary : NSObject

#pragma mark - Singleton Access

+ (instancetype) sharedLibrary;

#pragma mark - Ad Stack

- (HZAdModel *)peekAtAdForFetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType;
- (NSArray *)peekAtAllAds;

- (void)pushAd:(HZAdModel *)ad forFetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType;

- (HZAdModel *)popAdForFetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType;
- (void)purgeAd:(HZAdModel *)ad;


@end
