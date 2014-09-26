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

- (HZAdModel *)peekAtAdForAdUnit:(NSString *)adUnit tag:(NSString *)tag auctionType:(HZAuctionType)auctionType;
- (NSArray *)peekAtAllAds;

- (void)pushAd:(HZAdModel *)ad forAdUnit:(NSString *)adUnit tag:(NSString *)tag auctionType:(HZAuctionType)auctionType;

- (HZAdModel *)popAdForAdUnit:(NSString *)adUnit tag:(NSString *)tag auctionType:(HZAuctionType)auctionType;
- (void)purgeAd:(HZAdModel *)ad;


@end
