//
//  HZSegmentationSegment.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZSegmentationSegment.h"
#import "HZImpressionHistory.h"
#import "HZMediationConstants.h"

@implementation HZSegmentationSegment

- (nullable instancetype) initWithTimeInterval:(NSTimeInterval)interval forTags:(nullable NSArray *)tags adType:(HZAdType)adType auctionType:(HZAuctionType)auctionType limit:(NSUInteger)limit {
    self = [super init];
    if (self) {
        _timeInterval = interval;
        _adType = adType;
        _auctionType = auctionType;
        _adTags = tags;
        _impressionLimit = limit;
    }
    
    return self;
}

- (BOOL) limitsImpressionWithAdType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)tag {
    if(adType != self.adType || auctionType != self.auctionType) {
        // adType or auctionType mismatch
        return false;
    }
    
    if([self isFilteringForTags] && ![self.adTags containsObject:tag]) {
        // we are filtering by tags but the tag isn't present in our filter
        return false;
    }
    
    // type and tag match, check the counter over the time interval.
    return self.impressionCount >= self.impressionLimit;
}

- (NSUInteger) impressionCount {
    return [[HZImpressionHistory sharedInstance] countImpressionsSince:self.startTime withType:self.adType tags:self.adTags auctionType:self.auctionType];
    
}

- (NSDate *) startTime {
    // the beginning of the time range we care about is `self.timeInterval` seconds prior to now
    return [NSDate dateWithTimeIntervalSinceNow:(-1 * self.timeInterval)];
}

#pragma mark - Utilities

- (BOOL) isFilteringForTags {
    return self.adTags != nil;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"{[Segment] time interval: %f seconds, adType: %@, auctionType: %@, adTags: [%@], impression count/limit: %lu/%lu, limit counting from: %@ }", self.timeInterval, NSStringFromAdType(self.adType), NSStringFromHZAuctionType(self.auctionType), [self.adTags componentsJoinedByString:@", "], self.impressionCount, self.impressionLimit, [[self startTime] descriptionWithLocale:[NSLocale currentLocale]]];
}

@end