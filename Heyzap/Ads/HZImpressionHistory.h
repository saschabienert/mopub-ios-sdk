//
//  HZImpressionHistory.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/4/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZEnums.h"
#import "HZAdType.h"

@interface HZImpressionHistory : NSObject

+ (nullable instancetype) sharedInstance;


- (BOOL) recordImpressionWithType:(HZAdType)adType tag:(nonnull NSString *)tag auctionType:(HZAuctionType)auctionType;

/**
 *  Retrieve the number of impressions since a given date that had a given HZAdType, HZAuctionType, and tag. Passing `nil` for the tag means you don't care about searching based on tag.
 */
- (NSUInteger) countImpressionsSince:(nonnull NSDate *)timestamp withType:(HZAdType)adType tag:(nullable NSString *)tag auctionType:(HZAuctionType)auctionType;

/**
 *  Retrieve the number of impressions since a given date that had a given HZAdType, HZAuctionType, and one of an array of tags. Passing `nil` for the tags array means you don't care about searching based on tags.
 */
- (NSUInteger) countImpressionsSince:(nonnull NSDate *)timestamp withType:(HZAdType)adType tags:(nullable NSArray *)tags auctionType:(HZAuctionType)auctionType;

- (BOOL) deleteHistory;
@end