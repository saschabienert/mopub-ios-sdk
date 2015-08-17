//
//  HZSegmentationSegment.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZSegmentationController.h"
#import <sqlite3.h>

@interface HZSegmentationSegment : NSObject

@property (nonatomic, readonly) NSTimeInterval timeInterval; // number of seconds back the segment should look for impressions that fit the  parameters defined below
@property (nonatomic, readonly) HZAdType adType;
@property (nonatomic, readonly, nullable) NSArray * adTags; // nil == applies to any tag
@property (nonatomic, readonly) NSUInteger impressionLimit;
@property (nonatomic, readonly) HZAuctionType auctionType;

@property (nonatomic, readonly) BOOL isLoaded; // whether or not the segment has loaded it's history from HZImpressionHistory yet
@property (nonatomic, readonly, nullable) NSMutableOrderedSet *impressionHistory; // ordered set of timestamps at which impressions fitting this segment's search criteria occured, most recent first.

/**
 *  Returns YES if this segment currently restricts an impression of the given types and tag, NO if the impression is allowed.
 */
- (BOOL) limitsImpressionWithAdType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)tag;

/**
 *  Call this method with every impression. The method returns YES if the impression matches the segment's search criteria, NO otherwise. If the impression is a match, the segement will add the impression to it's impressionHistory.
 */
- (BOOL) recordImpressionWithAdType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)tag date:(nonnull NSDate *)date;

/* Init */
/**
 * Cretes a segment with the given time interval, ad type, list of tags it applies to, and impression limit.
    @param tags If nil, the segment applies to all ad tags, otherwise, it only applies to the ad tags in this array
 */
- (nullable instancetype) initWithTimeInterval:(NSTimeInterval)interval forTags:(nullable NSArray *)tags adType:(HZAdType)adType auctionType:(HZAuctionType)auctionType limit:(NSUInteger)limit;

- (void) loadWithDb:(nonnull sqlite3 *)db;

@end