//
//  HZSegmentation.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZSegmentationController.h"
#import "HZSegmentationSegment.h"
#import "HZCrossPromoAdapter.h"
#import "HZMediationConstants.h"
#import "HZImpressionHistory.h"
#import "HZDictionaryUtils.h"

@interface HZSegmentationController()
@property (nonnull, nonatomic) NSSet *segments;
@property (nonatomic) dispatch_queue_t impressionDbReadQueue;
@end

#define AUCTIONTYPE_STRING_FREQUENCY @"Frequency"
#define AUCTIONTYPE_STRING_CROSSPROMOFREQUENCY @"CrossPromoFrequency"
#define AUCTIONTYPE_STRINGS @[AUCTIONTYPE_STRING_FREQUENCY, AUCTIONTYPE_STRING_CROSSPROMOFREQUENCY]

@implementation HZSegmentationController

#pragma mark - Init / Setup

- (nullable instancetype) init {
    self = [super init];
    if (self) {
        _segments = [[NSMutableSet alloc] init];
        _impressionDbReadQueue = dispatch_queue_create("com.heyzap.sdk.mediation.segmentation.impressiondbread", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (void) setupFromMediationStart:(nonnull NSDictionary *)startDictionary {
    NSMutableArray * loadedSegments = [[NSMutableArray alloc] init];
    
    NSArray * segmentsResponse = [HZDictionaryUtils hzObjectForKey:@"segments" ofClass:[NSArray class] default:@[] withDict:startDictionary];
    for (NSDictionary *segmentDict in segmentsResponse) {
        NSArray *tags = nil;
        
        NSMutableArray *rules = [HZDictionaryUtils hzObjectForKey:@"rules" ofClass:[NSArray class] default:@[] withDict:segmentDict];
        rules = [rules mutableCopy];
        
        // backend has crosspromo/monitization as two rules under the same segment, with the timeInterval, limit, type, enabled, and quantity under those divisions. we treat these as separate segments in the sdk
        // pull the auctiontype rules out, process the others (tags), and apply these to the per-auctiontype rules (time, limit, quantity, type, enabled) to create segments
        NSIndexSet *auctionTypeRuleIndexes = [rules indexesOfObjectsPassingTest:^BOOL(NSDictionary * rule, NSUInteger idx, BOOL *stop) {
            NSString *ruleType = [HZDictionaryUtils hzObjectForKey:@"type" ofClass:[NSString class] default:@"" withDict:rule];
            if ([AUCTIONTYPE_STRINGS containsObject:ruleType]) {
                return YES;
            }
            return NO;
        }];
        
        NSArray *auctionTypeRules = [rules objectsAtIndexes:auctionTypeRuleIndexes];
        [rules removeObjectsAtIndexes:auctionTypeRuleIndexes];
        
        for (NSDictionary * rule in rules) {
            // current non-auctiontype based rules: tags
            NSString *ruleType = [HZDictionaryUtils hzObjectForKey:@"type" ofClass:[NSString class] default:@"" withDict:rule];
            if ([ruleType isEqualToString:@"Tag"]) {
                NSDictionary *options = [HZDictionaryUtils hzObjectForKey:@"options" ofClass:[NSDictionary class] default:@{} withDict:rule];
                tags = [HZDictionaryUtils hzObjectForKey:@"tags" ofClass:[NSArray class] default:nil withDict:options];
            }
        }
        
        // now that the non-auctiontype rules are pulled out, process each auctiontype rule and create segments with them
        for (NSDictionary *auctionTypeRule in auctionTypeRules) {
           HZAuctionType auctionType = [self auctionTypeFromAuctionTypeString:[HZDictionaryUtils hzObjectForKey:@"type" ofClass:[NSString class] default:@"" withDict:auctionTypeRule]];
            
            NSDictionary *options = [HZDictionaryUtils hzObjectForKey:@"options" ofClass:[NSDictionary class] default:@{} withDict:auctionTypeRule];
            
            BOOL adsEnabled = [[HZDictionaryUtils hzObjectForKey:@"ads_enabled" ofClass:[NSNumber class] default:@0 withDict:options] boolValue];
            
            if (adsEnabled) {
            
                NSArray *frequencyLimits = [HZDictionaryUtils hzObjectForKey:@"frequency_limits" ofClass:[NSArray class] default:@[] withDict:options];
                for (NSDictionary *frequencyLimitOptions in frequencyLimits) {
                    NSTimeInterval timeInterval = [[HZDictionaryUtils hzObjectForKey:@"seconds" ofClass:[NSNumber class] default:@0 withDict:frequencyLimitOptions] doubleValue];
                    NSUInteger impressionLimit = [[HZDictionaryUtils hzObjectForKey:@"ads_quantity" ofClass:[NSNumber class] default:@0 withDict:frequencyLimitOptions] unsignedIntegerValue];
                    
                    HZCreativeType creativeType = hzCreativeTypeFromNSNumber([HZDictionaryUtils hzObjectForKey:@"ad_format" ofClass:[NSNumber class] default:@(HZCreativeTypeUnknown) withDict:frequencyLimitOptions]);
                    
                    [loadedSegments addObject:[[HZSegmentationSegment alloc] initWithTimeInterval:timeInterval forTags:tags creativeType:creativeType auctionType:auctionType limit:impressionLimit adsEnabled:adsEnabled]];
                }
            } else {
                // ads disabled - the frequency limits don't matter / might not even exist. The only settings we care about for this segment are the auctionType, the tags to apply them to, a limit of 0 since ads are disabled, and the fact that ads are disabled. (It should apply to all creativeTypes over any time period)
                [loadedSegments addObject:[[HZSegmentationSegment alloc] initWithTimeInterval:0 forTags:tags creativeType:HZCreativeTypeUnknown auctionType:auctionType limit:0 adsEnabled:NO]];
            }
        }
        
    }
    
    self.segments = [NSSet setWithArray:loadedSegments];
    
    // send segments off to retrieve their persisted history
    [self loadSegmentsFromImpressionHistory];
    
}

- (void) loadSegmentsFromImpressionHistory {
    dispatch_async(self.impressionDbReadQueue, ^{
        sqlite3 *db = [[HZImpressionHistory sharedInstance] safeImpressionTableDatabaseConnection];
        if(!db) {
            HZELog(@"HZSegmentationController failing to load db connection to read segment history.");
            return;
        }
        
        for(HZSegmentationSegment *segment in self.segments) {
            [segment loadWithDb:db];
        }
        
        sqlite3_close(db);
        HZDLog(@"HZSegmentationController: Active segments for this user: %@", self.segments);
    });
}


#pragma mark - Query

- (BOOL) bannerAdapterHasAllowedAd:(nonnull HZBannerAdapter *)adapter tag:(nonnull NSString *)adTag {
    return [adapter isAvailable] && [self isAdAllowedForCreativeType:HZCreativeTypeBanner auctionType:[HZSegmentationController auctionTypeForAdapter:adapter.parentAdapter] tag:adTag];
}

- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter forCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)adTag {
    return [adapter hasAdForCreativeType:creativeType] && [self isAdAllowedForCreativeType:creativeType auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] tag:adTag];
}

- (BOOL) isAdAllowedForCreativeType:(HZCreativeType)creativeType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)adTag {
    __block BOOL didGetLimited = NO;
    [self.segments enumerateObjectsUsingBlock:^(HZSegmentationSegment *segment, BOOL *stop) {
        if([segment limitsImpressionWithCreativeType:creativeType auctionType:auctionType tag:adTag]) {
            HZDLog(@"HZSegmentation: ad not allowed for type: %@, auctionType: %@, tag: %@. First segment limiting impression: %@", NSStringFromCreativeType(creativeType), NSStringFromHZAuctionType(auctionType), adTag, segment);
            didGetLimited = YES;
            *stop = YES;
        }
    }];
    
    return !didGetLimited;
}


#pragma mark - Report

- (void) recordImpressionWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag adapter:(nonnull HZBaseAdapter *)adapter {
    NSDate *date = [NSDate date];
    for(HZSegmentationSegment *segment in self.segments) {
        [segment recordImpressionWithCreativeType:creativeType auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] tag:tag date:date];
    }
    
    [[HZImpressionHistory sharedInstance] recordImpressionWithCreativeType:creativeType tag:tag auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] date:date];
}


#pragma mark - Utilities

+ (HZAuctionType) auctionTypeForAdapter:(nonnull HZBaseAdapter *)adapter {
    return [adapter class] == [HZCrossPromoAdapter class] ? HZAuctionTypeCrossPromo : HZAuctionTypeMonetization;
}

- (BOOL) clearImpressionHistory {
    if (![[HZImpressionHistory sharedInstance] deleteHistory]) {
        return NO;
    }
    
    [self loadSegmentsFromImpressionHistory];
    return YES;
}

- (HZAuctionType) auctionTypeFromAuctionTypeString:(NSString *)auctionTypeString {
    if ([auctionTypeString isEqualToString:AUCTIONTYPE_STRING_CROSSPROMOFREQUENCY]) {
        return HZAuctionTypeCrossPromo;
    } else if([auctionTypeString isEqualToString:AUCTIONTYPE_STRING_FREQUENCY]) {
        return HZAuctionTypeMonetization;
    }
    
    HZELog(@"HZSegmentationController: unregcognized auctionType string: %@. Processing it as HZAuctionTypeMonetization.", auctionTypeString);
    return HZAuctionTypeMonetization;
}


@end