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


#pragma mark - Init

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

- (void) loadWithDb:(nonnull sqlite3 *)db{
    _impressionHistory = [[HZImpressionHistory sharedInstance] impressionsSince:self.startTime withType:self.adType tags:self.adTags auctionType:self.auctionType databaseConnection:db mostRecentFirst:YES];
}


#pragma mark - Query/Update

- (BOOL) recordImpressionWithAdType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)tag date:(nonnull NSDate *)date {
    if(!self.isLoaded) {
        HZELog(@"HZSegmentationSegment: trying to record an impression before loaded.");
        return NO;
    }
    
    if(adType != self.adType || auctionType != self.auctionType) {
        // adType or auctionType mismatch
        return NO;
    }
    
    if([self isFilteringForTags] && ![self.adTags containsObject:tag]) {
        // we are filtering by tags but the tag isn't present in our filter
        return NO;
    }
    
    // type and tag match, record impression
    [self.impressionHistory insertObject:date atIndex:0];
    return YES;
}

- (BOOL) limitsImpressionWithAdType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)tag {
    if(!self.isLoaded) {
        // don't limit impressions if there is a failure with the impression history system
        HZELog(@"HZSegmentationSegment: asked about limits before loaded.");
        return NO;
    }
    
    if(adType != self.adType || auctionType != self.auctionType) {
        // adType or auctionType mismatch
        return NO;
    }
    
    if([self isFilteringForTags] && ![self.adTags containsObject:tag]) {
        // we are filtering by tags but the tag isn't present in our filter
        return NO;
    }
    
    // type and tag match, check the counter over the time interval.
    return self.impressionCount >= self.impressionLimit;
}


#pragma mark - Utilities

- (NSUInteger) impressionCount {
    if (!self.isLoaded) {
        return 0;
    }
    
    NSDate *earliestImpressionToKeep = [self startTime];
    
    // prune impressionHistory for old times we don't care about anymore
    // impressionHistory is ordered with most recent impressions first
    NSUInteger firstIndexToRemove = [self.impressionHistory indexOfObjectPassingTest:^BOOL(NSDate *obj, NSUInteger idx, BOOL *stop) {
        if ([earliestImpressionToKeep compare:obj] == NSOrderedDescending) {
            //start time is later than the impression time
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if (firstIndexToRemove != NSNotFound) {
        // remove all times after and including this index - they are older than we care about
        [self.impressionHistory removeObjectsInRange:NSMakeRange(firstIndexToRemove, self.impressionHistory.count - firstIndexToRemove)];
    }
                           
    return [self.impressionHistory count];
}

- (NSDate *) startTime {
    // the beginning of the time range we care about is `self.timeInterval` seconds prior to now
    return [NSDate dateWithTimeIntervalSinceNow:(-1 * self.timeInterval)];
}

- (BOOL) isLoaded {
    return self.impressionHistory != nil;
}


- (BOOL) isFilteringForTags {
    return self.adTags != nil;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"{[Segment] time interval: %f seconds, adType: %@, auctionType: %@, adTags: [%@], impression count/limit: %lu/%lu, limit counting from: %@ %@}", self.timeInterval, NSStringFromAdType(self.adType), NSStringFromHZAuctionType(self.auctionType), [self.adTags componentsJoinedByString:@", "], (unsigned long)self.impressionCount, (unsigned long)self.impressionLimit, [[self startTime] descriptionWithLocale:[NSLocale currentLocale]], (self.isLoaded ? @"" : @" -- Not yet loaded from db --")];
}

@end