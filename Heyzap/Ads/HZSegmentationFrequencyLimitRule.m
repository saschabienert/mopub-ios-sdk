//
//  HZSegmentationFrequencyLimitRule.m
//  Heyzap
//
//  Created by Monroe Ekilah on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZSegmentationFrequencyLimitRule.h"
#import "HZSegmentationSegment.h"
#import "HZImpressionHistory.h"

@interface HZSegmentationFrequencyLimitRule ()

@property (atomic, nullable) NSMutableOrderedSet<NSDate *> *impressionHistory; // ordered set of timestamps at which impressions fitting this segment's search criteria occured, most recent first. atomic since `loadWithDb:` can be called on any thread, as can the methods that access this property

@end

@implementation HZSegmentationFrequencyLimitRule

- (nullable instancetype) init {
    self = [super init];
    if (self) {
        _timeInterval = [NSDate timeIntervalSinceReferenceDate]; //default to a huge interval
        _adsEnabled = YES;
        _auctionType = HZAuctionTypeMixed;
        _creativeType = HZCreativeTypeUnknown;
        _impressionLimit = NSUIntegerMax; // no limit by default
    }
    
    return self;
}

- (void) loadWithDb:(nonnull sqlite3 *)db {
    _impressionHistory = [[HZImpressionHistory sharedInstance] impressionsSince:self.startTime withCreativeType:self.creativeType tags:[self adTags] auctionType:self.auctionType databaseConnection:db mostRecentFirst:YES];
}

- (BOOL) recordImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter date:(nonnull NSDate *)date {
    if (!self.adsEnabled) {
        return NO;
    }
    
    if(!self.isLoaded) {
        HZELog(@"HZSegmentationSegment: trying to record an impression before loaded.");
        return NO;
    }
    
    if (![self appliesToRequestWithAdapter:adapter]) {
        // adapter mismatch
        return NO;
    }
    
    if(![self appliesToCreativeType:creativeType]) {
        // creativeType mismatch
        return NO;
    }
    
    // type and tag match, record impression
    [self.impressionHistory insertObject:date atIndex:0];
    return YES;
}


- (BOOL) limitsImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter tag:(nonnull NSString *)tag {
    
    if (![self appliesToRequestWithAdapter:adapter]) {
        return NO;
    }
    
    if (!self.adsEnabled) {
        return YES;
    }
    
    // only check creativeType if ads are enabled, since creative type might not have been specified if they're disabled
    if (![self appliesToCreativeType:creativeType]) {
        // creativeType mismatch
        return NO;
    }
    
    // this freq. cap definitely applies to the pending impression. check the counter over the time interval.
    return self.impressionCount >= self.impressionLimit;
}



#pragma mark - Utilities

- (NSUInteger) impressionCount {
    if (!self.isLoaded) {
        HZELog(@"HZSegmentationSegment: asked about impressionCount before loaded.");
        return 0;
    }
    
    NSDate *earliestImpressionToKeep = [self startTime];
    
    // prune impressionHistory for old times we don't care about anymore
    // impressionHistory is ordered with most recent impressions first
    NSUInteger firstIndexToRemove = [self.impressionHistory indexOfObjectPassingTest:^BOOL(NSDate *obj, NSUInteger idx, BOOL *stop) {
        if ([earliestImpressionToKeep compare:obj] == NSOrderedDescending) {
            //start time is later than the impression times
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

- (nonnull NSArray<NSString *> *) adTags {
    if (self.parentSegment) {
        return [self.parentSegment adTags];
    }
    
    return @[];
}


- (BOOL) appliesToCreativeType:(HZCreativeType)creativeType {
    if (self.creativeType == HZCreativeTypeUnknown) {
        return YES;
    }
    
    return self.creativeType == creativeType;
}

- (BOOL) appliesToRequestWithAdapter:(HZBaseAdapter *)adapter {
    if (self.auctionType != HZAuctionTypeMixed && [HZSegmentationController auctionTypeForAdapter:adapter] != self.auctionType) {
        // auctionType mismatch
        return NO;
    }
    
    return YES;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"{[Frequency Rule] time interval: %i seconds, creativeType: %@, auctionType: %@, adTags: [%@], ads enabled: %@, impression count/limit: %lu/%lu segment name: \"%@\" %@}", (int)self.timeInterval, (self.creativeType == HZCreativeTypeUnknown ? @"ALL" : NSStringFromCreativeType(self.creativeType)), NSStringFromHZAuctionType(self.auctionType), [[self adTags] componentsJoinedByString:@", "], (self.adsEnabled ? @"yes" : @"no"), (unsigned long)self.impressionCount, (unsigned long)self.impressionLimit, self.parentSegment.name, (self.isLoaded ? @"" : @" -- Not yet loaded from db --")];
}

@end