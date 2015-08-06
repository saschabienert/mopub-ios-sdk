//
//  HZSegmentationSegment.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZSegmentationController.h"

@interface HZSegmentationSegment : NSObject

@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic) HZAdType adType;
@property (nonatomic, nullable) NSArray * adTags; // nil == applies to any tag
@property (nonatomic) NSUInteger impressionLimit;
@property (nonatomic) HZAuctionType auctionType;

- (BOOL) limitsImpressionWithAdType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)tag;

/* Init */
/**
 * Cretes a segment with the given time interval, ad type, list of tags, and impression limit. The start time is now, and the starting impression count is 0.
    @param tags If nil, the segment applies to all ad tags, otherwise, it only applies to the ad tags in this array
 */
- (nullable instancetype) initWithTimeInterval:(NSTimeInterval)interval forTags:(nullable NSArray *)tags adType:(HZAdType)adType auctionType:(HZAuctionType)auctionType limit:(NSUInteger)limit;

@end