//
//  HZSegmentationSegment.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZSegmentationController.h"
#import "HZSegmentationFrequencyLimitRule.h"
#import <sqlite3.h>

@interface HZSegmentationSegment : NSObject

@property (nonatomic, readonly, nullable) NSString *name;

@property (nonatomic, readonly, nonnull) NSSet<NSString *> *adTags; // empty == applies to any tag
@property (nonatomic, readonly, nonnull) NSSet<NSString *> *disabledNetworks;

@property (nonatomic, readonly, nonnull) NSArray<HZSegmentationFrequencyLimitRule *> *frequencyLimitRules;

@property (nonatomic, readonly, nonnull) NSDictionary <NSString *, NSString *>* placementIDOverrides;

/**
 *  Returns YES if this segment currently restricts an impression of the given types and tag, NO if the impression is allowed.
 */
- (BOOL) limitsImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter tag:(nonnull NSString *)tag;

/**
 *  Returns YES if this segment should apply to a request with the given tag, NO otherwise.
 */
- (BOOL) appliesToRequestWithTag:(nonnull NSString *)tag;

/**
 *  Call this method with every impression. The method returns YES if the impression matches the segment's criteria, NO otherwise. If the impression is a match, the segement will add the impression to it's impressionHistory.
 */
- (BOOL) recordImpressionWithCreativeType:(HZCreativeType)creativeType adapter:(nonnull HZBaseAdapter *)adapter tag:(nonnull NSString *)tag date:(nonnull NSDate *)date;

/* Init */
/**
 * Cretes a segment with the given list of tags this segment applies to, disabled networks, placement ID overrides, and name.
    @param tags If empty, the segment applies to all ad tags, otherwise, it only applies to the ad tags in this array
 */
- (nullable instancetype) initWithTags:(nonnull NSSet *)tags disabledNetworks:(nonnull NSSet *)disabledNetworks placementIDOverrides:(nonnull NSDictionary <NSString *, NSString *>*)placementIDOverrides frequencyLimitRules:(nonnull NSArray <HZSegmentationFrequencyLimitRule *> *)frequencyLimitRules name:(nullable NSString *)name;

- (void) loadWithDb:(nonnull sqlite3 *)db;

@end