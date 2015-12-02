//
//  HZNativeAdController_Private.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/16/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZNativeAdController.h"
#import "HZEnums.h"

@interface HZNativeAdController ()

+ (void)fetchAds:(NSUInteger)numberOfAds
             tag:(NSString *)tag
     auctionType:(HZAuctionType)auctionType
      completion:(void (^)(NSError *error, HZNativeAdCollection *collection))completion;

@end