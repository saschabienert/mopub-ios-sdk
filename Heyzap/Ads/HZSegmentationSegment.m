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
#import "HZSegmentationFrequencyLimitRule.h"


@interface HZSegmentationSegment()

@property (nonatomic, nonnull) NSSet<NSString *> *adTags; // empty == applies to any tag
@property (nonatomic, nonnull) NSSet<NSString *> *disabledNetworks; // empty == no disabled networks

@property (nonatomic, nonnull) NSArray<HZSegmentationFrequencyLimitRule *> *frequencyLimitRules;

@property (nonatomic, nonnull) NSDictionary <NSString *, NSDictionary<NSString *, NSString *> *>* placementIDOverrides;


@end

@implementation HZSegmentationSegment


#pragma mark - Init

- (nullable instancetype) initWithTags:(nonnull NSSet <NSString *> *)tags disabledNetworks:(nonnull NSSet <NSString *> *)disabledNetworks placementIDOverrides:(nonnull NSDictionary <NSString *, NSDictionary<NSString *, NSString *> *>*)placementIDOverrides frequencyLimitRules:(nonnull NSArray <HZSegmentationFrequencyLimitRule *> *)frequencyLimitRules name:(nullable NSString *)name {
    self = [super init];
    if (self) {
        _adTags = tags;
        _disabledNetworks = disabledNetworks;
        _placementIDOverrides = placementIDOverrides;
        _name = name;
        _frequencyLimitRules = frequencyLimitRules;
        
        for(HZSegmentationFrequencyLimitRule *rule in _frequencyLimitRules) {
            rule.parentSegment = self; // frequency rules need a weak reference back to us so they can get the tags we apply to
        }
    }
    
    return self;
}

- (void) loadWithDb:(nonnull sqlite3 *)db{
    for (HZSegmentationFrequencyLimitRule *rule in self.frequencyLimitRules) {
        [rule loadWithDb:db];
    }
}


#pragma mark - Query/Update

- (BOOL) recordImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter tag:(nonnull NSString *)tag date:(nonnull NSDate *)date {
    
    if (![self appliesToRequestWithTag:tag]) {
        // tag mismatch
        return NO;
    }
    
    // tell freq limits to try and record impression in their histories, return YES if one of them do
    BOOL didRecordOnALimit = NO;
    for (HZSegmentationFrequencyLimitRule *rule in self.frequencyLimitRules) {
        BOOL didRecord = [rule recordImpressionWithCreativeType:creativeType adapter:adapter date:date];
        didRecordOnALimit |= didRecord;
    }
    return didRecordOnALimit;
}

- (BOOL) limitsImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter tag:(nonnull NSString *)tag {
    if (![self appliesToRequestWithTag:tag]) {
        return NO;
    }
    
    if ([self isAdapterDisabled:adapter]) {
        // this segment applies to the request, and the network is disabled in this segment
        return YES;
    }
    
    // check freq limits
    BOOL frequencyRuleLimitsImpression = NO;
    for (HZSegmentationFrequencyLimitRule *rule in self.frequencyLimitRules) {
        if ([rule limitsImpressionWithCreativeType:creativeType adapter:adapter]) {
            frequencyRuleLimitsImpression = YES;
            HZDLog(@"HZSegmentationSegment: first frequency rule limiting impression: %@", rule);
            break;
        }
    }
    return frequencyRuleLimitsImpression;
}

- (BOOL) appliesToRequestWithTag:(NSString *)tag {
    if ([self isFilteringForTags] && ![self.adTags containsObject:tag]) {
        // we are filtering by tags but the tag isn't present in our filter
        return NO;
    }
    return YES;
}


#pragma mark - Utilities

- (BOOL) isLoaded {
    for (HZSegmentationFrequencyLimitRule *rule in self.frequencyLimitRules) {
        if (![rule isLoaded])return NO;
    }
    return YES;
}

- (BOOL) isFilteringForTags {
    return [self.adTags count] > 0;
}

- (BOOL) isAdapterDisabled:(nonnull HZBaseAdapter *)adapter {
    return [self.disabledNetworks containsObject:[adapter name]];
}


- (NSString *) description {
    return [NSString stringWithFormat:@"{[Segment] name: \"%@\"  tags: [%@], disabled networks: [%@], placement ID overrides: %@ %@ Frequency Limits: %@}", self.name, [self.adTags.allObjects componentsJoinedByString:@", "], [self.disabledNetworks.allObjects componentsJoinedByString:@", "], self.placementIDOverrides,  (self.isLoaded ? @"" : @" -- Not yet loaded from db --"), self.frequencyLimitRules];
}

@end