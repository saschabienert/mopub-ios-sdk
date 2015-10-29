//
//  HZSegmentationFrequencyLimitRule.h
//  Heyzap
//
//  Created by Monroe Ekilah on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
@class HZSegmentationSegment;

@interface HZSegmentationFrequencyLimitRule : NSObject

@property (nonatomic) NSTimeInterval timeInterval; // number of seconds back the segment should look for impressions that fit the  parameters defined below
@property (nonatomic) HZCreativeType creativeType;
@property (nonatomic) NSUInteger impressionLimit;
@property (nonatomic) HZAuctionType auctionType;
@property (nonatomic, weak) HZSegmentationSegment *parentSegment; // weak reference to parent segment for getting tags
@property (nonatomic) BOOL adsEnabled; // will ignore the limit & interval if this is NO - it's an on/off switch for ads with the specified type/tag/auctionType

@property (nonatomic, readonly) BOOL isLoaded; // whether or not the frequency limit has loaded its impression history from HZImpressionHistory yet


- (nullable instancetype) init;

- (void) loadWithDb:(nonnull sqlite3 *)db;

- (BOOL) recordImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter date:(nonnull NSDate *)date;
- (BOOL) limitsImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter tag:(nonnull NSString *)tag;

@end