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
        _enabled = YES;
    }
    
    return self;
}

- (void) setEnabled:(BOOL)enabled {
    _enabled = enabled;
    HZDLog(@"HZSegmentationController %@", enabled ? @"enabled." : @"disabled!");
}

- (void) setupFromMediationStart:(nonnull NSDictionary *)startDictionary completion:(nullable void (^)(BOOL finished))completion {
    NSMutableArray * loadedSegments = [[NSMutableArray alloc] init];
    
    NSArray * segmentsResponse = [HZDictionaryUtils objectForKey:@"segments" ofClass:[NSArray class] default:@[] dict:startDictionary];
    for (NSDictionary *segmentDict in segmentsResponse) {
        NSArray *tags = nil;
        NSString *name = [HZDictionaryUtils objectForKey:@"name" ofClass:[NSString class] default:nil dict:segmentDict];
        
        NSMutableArray *rules = [HZDictionaryUtils objectForKey:@"rules" ofClass:[NSArray class] default:@[] dict:segmentDict];
        rules = [rules mutableCopy];
        
        // backend has crosspromo/monetization as two rules under the same segment, with the timeInterval, limit, type, enabled, and quantity under those divisions. we treat these as separate segments in the sdk
        // pull the auctiontype rules out, process the others (tags), and apply these to the per-auctiontype rules (time, limit, quantity, type, enabled) to create segments
        NSIndexSet *auctionTypeRuleIndexes = [rules indexesOfObjectsPassingTest:^BOOL(NSDictionary * rule, NSUInteger idx, BOOL *stop) {
            NSString *ruleType = [HZDictionaryUtils objectForKey:@"type" ofClass:[NSString class] default:@"" dict:rule];
            if ([AUCTIONTYPE_STRINGS containsObject:ruleType]) {
                return YES;
            }
            return NO;
        }];
        
        NSArray *auctionTypeRules = [rules objectsAtIndexes:auctionTypeRuleIndexes];
        [rules removeObjectsAtIndexes:auctionTypeRuleIndexes];
        
        for (NSDictionary * rule in rules) {
            // current non-auctiontype based rules: tags
            NSString *ruleType = [HZDictionaryUtils objectForKey:@"type" ofClass:[NSString class] default:@"" dict:rule];
            if ([ruleType isEqualToString:@"Tag"]) {
                NSDictionary *options = [HZDictionaryUtils objectForKey:@"options" ofClass:[NSDictionary class] default:@{} dict:rule];
                tags = [HZDictionaryUtils objectForKey:@"tags" ofClass:[NSArray class] default:nil dict:options];
            }
        }
        
        // now that the non-auctiontype rules are pulled out, process each auctiontype rule and create segments with them
        for (NSDictionary *auctionTypeRule in auctionTypeRules) {
            HZAuctionType auctionType = [HZSegmentationController auctionTypeFromAuctionTypeString:[HZDictionaryUtils objectForKey:@"type" ofClass:[NSString class] default:@"" dict:auctionTypeRule]];
            NSDictionary *options = [HZDictionaryUtils objectForKey:@"options" ofClass:[NSDictionary class] default:@{} dict:auctionTypeRule];
            
            BOOL adsEnabled = [[HZDictionaryUtils objectForKey:@"ads_enabled" ofClass:[NSNumber class] default:@0 dict:options] boolValue];
            if (adsEnabled) {
                NSArray *frequencyLimits = [HZDictionaryUtils objectForKey:@"frequency_limits" ofClass:[NSArray class] default:@[] dict:options];
                for (NSDictionary *frequencyLimitOptions in frequencyLimits) {
                    NSTimeInterval timeInterval = [[HZDictionaryUtils objectForKey:@"seconds" ofClass:[NSNumber class] default:@0 dict:frequencyLimitOptions] doubleValue];
                    NSUInteger impressionLimit = [[HZDictionaryUtils objectForKey:@"ads_quantity" ofClass:[NSNumber class] default:@0 dict:frequencyLimitOptions] unsignedIntegerValue];
                    
                    HZCreativeType creativeType = hzCreativeTypeFromNSNumber([HZDictionaryUtils objectForKey:@"ad_format" ofClass:[NSNumber class] default:@(HZCreativeTypeUnknown) dict:frequencyLimitOptions]);
                    
                    [loadedSegments addObject:[[HZSegmentationSegment alloc] initWithTimeInterval:timeInterval forTags:tags creativeType:creativeType auctionType:auctionType limit:impressionLimit adsEnabled:adsEnabled name:name]];
                }
            } else {
                // ads disabled - the frequency limits don't matter / might not even exist. The only settings we care about for this segment are the auctionType & the tags to apply them to. We use a limit of 0 since ads are disabled. (It should apply to all creativeTypes over any time period)
                [loadedSegments addObject:[[HZSegmentationSegment alloc] initWithTimeInterval:0 forTags:tags creativeType:HZCreativeTypeUnknown auctionType:auctionType limit:0 adsEnabled:NO name:name]];
            }
        }
    }
    
    self.segments = [NSSet setWithArray:loadedSegments];
    
    // send segments off to retrieve their persisted history
    [self loadSegmentsFromImpressionHistoryWithCompletion:completion];
}

- (void) loadSegmentsFromImpressionHistoryWithCompletion:(nullable void (^)(BOOL successful))completion {
    dispatch_async(self.impressionDbReadQueue, ^{
        sqlite3 *db = [[HZImpressionHistory sharedInstance] safeImpressionTableDatabaseConnection];
        if(!db) {
            HZELog(@"HZSegmentationController failing to load db connection to read segment history.");
            if (completion) {
                dispatch_async(dispatch_get_main_queue() , ^{
                    completion(NO);
                });
            }
            return;
        }
        
        for(HZSegmentationSegment *segment in self.segments) {
            [segment loadWithDb:db];
        }
        
        sqlite3_close(db);
        HZDLog(@"HZSegmentationController: Active segments for this user: %@", self.segments);
        if (completion) {
            dispatch_async(dispatch_get_main_queue() , ^{
                completion(YES);
            });
        }
    });
}


#pragma mark - Query

- (BOOL) bannerAdapterHasAllowedAd:(nonnull HZBannerAdapter *)bannerAdapter tag:(nonnull NSString *)adTag {
    return [bannerAdapter isAvailable] && [self allowBannerAdapter:bannerAdapter toShowAdForTag:adTag];
}

- (BOOL) allowBannerAdapter:(nonnull HZBannerAdapter *)bannerAdapter toShowAdForTag:(nonnull NSString *)adTag {
    return [self isAdAllowedForCreativeType:HZCreativeTypeBanner auctionType:[HZSegmentationController auctionTypeForAdapter:bannerAdapter.parentAdapter] tag:adTag];
}

- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter forCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)adTag {
    return [adapter hasAdForCreativeType:creativeType] && [self allowAdapter:adapter toShowAdForCreativeType:creativeType tag:adTag];
}

- (BOOL) allowAdapter:(nonnull HZBaseAdapter *)adapter toShowAdForCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)adTag {
    return [self isAdAllowedForCreativeType:creativeType auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] tag:adTag];
}

- (BOOL) isAdAllowedForCreativeType:(HZCreativeType)creativeType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)adTag {
    if (!self.enabled) {
        return YES;
    }
    
    __block BOOL didGetLimited = NO;
    [self.segments enumerateObjectsUsingBlock:^(HZSegmentationSegment *segment, BOOL *stop) {
        if([segment limitsImpressionWithCreativeType:creativeType auctionType:auctionType tag:adTag]) {
            //HZDLog(@"HZSegmentation: ad not allowed for type: %@, auctionType: %@, tag: %@. First segment limiting impression: %@", NSStringFromCreativeType(creativeType), NSStringFromHZAuctionType(auctionType), adTag, segment);
            didGetLimited = YES;
            *stop = YES;
        }
    }];
    
    return !didGetLimited;
}


#pragma mark - Report

- (void) recordImpressionWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag adapter:(nonnull HZBaseAdapter *)adapter {
    if (!self.enabled) {
        return;
    }
    
    NSDate *date = [NSDate date];
    for(HZSegmentationSegment *segment in self.segments) {
        [segment recordImpressionWithCreativeType:creativeType auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] tag:tag date:date];
    }
    
    [[HZImpressionHistory sharedInstance] recordImpressionWithCreativeType:creativeType tag:tag auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] date:date];
}


#pragma mark - Utilities

- (void) clearImpressionHistoryWithCompletion:(nullable void (^)(BOOL successful))completion {
    if (![[HZImpressionHistory sharedInstance] deleteHistory]) {
        if(completion) completion(NO);
        return;
    }
    
    [self loadSegmentsFromImpressionHistoryWithCompletion:completion];
}

+ (HZAuctionType) auctionTypeForAdapter:(nonnull HZBaseAdapter *)adapter {
    return [adapter class] == [HZCrossPromoAdapter class] ? HZAuctionTypeCrossPromo : HZAuctionTypeMonetization;
}

+ (HZAuctionType) auctionTypeFromAuctionTypeString:(NSString *)auctionTypeString {
    if ([auctionTypeString isEqualToString:AUCTIONTYPE_STRING_CROSSPROMOFREQUENCY]) {
        return HZAuctionTypeCrossPromo;
    } else if([auctionTypeString isEqualToString:AUCTIONTYPE_STRING_FREQUENCY]) {
        return HZAuctionTypeMonetization;
    }
    
    HZELog(@"HZSegmentationController: unregcognized auctionType string: %@. Processing it as HZAuctionTypeMonetization.", auctionTypeString);
    return HZAuctionTypeMonetization;
}


@end