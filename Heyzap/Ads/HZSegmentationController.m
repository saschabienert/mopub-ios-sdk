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
#import "HZSegmentationFrequencyLimitRule.h"

@interface HZSegmentationController()
@property (nonnull, nonatomic) NSSet<HZSegmentationSegment *> *segments;
@property (nonatomic) dispatch_queue_t impressionDbReadQueue;
@end

#define RULETYPE_MONETIZING_ADS_FREQUENCY @"Frequency"
#define RULETYPE_CROSSPROMO_ADS_FREQUENCY @"CrossPromoFrequency"
#define RULETYPE_TAG_FILTER @"Tag"
#define RULETYPE_PLACEMENT_ID_OVERRIDES @"PlacementId"
#define RULETYPE_NETWORK_DISABLES @"Network"

#define RULEKEY_TYPE @"type"
#define RULEKEY_OPTIONS @"options"

#define OPTIONKEY_TAGS @"tags"
#define OPTIONKEY_NETWORKS @"networks"

#define SEGMENTKEY_NAME @"name"
#define SEGMENTKEY_RULES @"rules"

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
        NSSet *tags = [NSSet set];
        NSDictionary <NSString *, NSString *>* placementIDOverrides = @{};
        NSSet *disabledNetworks = [NSSet set];
        NSString *name = [HZDictionaryUtils objectForKey:SEGMENTKEY_NAME ofClass:[NSString class] default:nil dict:segmentDict];
        
        NSMutableArray *rules = [HZDictionaryUtils objectForKey:SEGMENTKEY_RULES ofClass:[NSArray class] default:@[] dict:segmentDict];
        rules = [rules mutableCopy];
        
        NSMutableArray<HZSegmentationFrequencyLimitRule *> *frequencyRules = [NSMutableArray array];
        
        for (NSDictionary * rule in rules) {
            NSString *ruleType = [HZDictionaryUtils objectForKey:RULEKEY_TYPE ofClass:[NSString class] default:@"" dict:rule];

            if ([ruleType isEqualToString:RULETYPE_TAG_FILTER]) {
                NSDictionary *options = [HZDictionaryUtils objectForKey:RULEKEY_OPTIONS ofClass:[NSDictionary class] default:@{} dict:rule];
                tags = [NSSet setWithArray:[HZDictionaryUtils objectForKey:OPTIONKEY_TAGS ofClass:[NSArray class] default:@[] dict:options]];
                
            } else if ([ruleType isEqualToString:RULETYPE_PLACEMENT_ID_OVERRIDES]) {
                // options dict ~= {"network" => {"creativeType" => "new_placement_id"}}
                placementIDOverrides = [HZDictionaryUtils objectForKey:RULEKEY_OPTIONS ofClass:[NSDictionary class] default:@{} dict:rule];
                
            } else if ([ruleType isEqualToString:RULETYPE_NETWORK_DISABLES]) {
                NSDictionary *options = [HZDictionaryUtils objectForKey:RULEKEY_OPTIONS ofClass:[NSDictionary class] default:@{} dict:rule];
                disabledNetworks = [NSSet setWithArray:[HZDictionaryUtils objectForKey:OPTIONKEY_NETWORKS ofClass:[NSArray class] default:@[] dict:options]];
                
            } else if ([ruleType isEqualToString:RULETYPE_MONETIZING_ADS_FREQUENCY]
                       || [ruleType isEqualToString:RULETYPE_CROSSPROMO_ADS_FREQUENCY]) {
                
                HZAuctionType auctionType = [HZSegmentationController auctionTypeFromAuctionTypeString:ruleType];
                
                NSDictionary *options = [HZDictionaryUtils objectForKey:RULEKEY_OPTIONS ofClass:[NSDictionary class] default:@{} dict:rule];
                BOOL adsEnabled = [[HZDictionaryUtils objectForKey:@"ads_enabled" ofClass:[NSNumber class] default:@1 dict:options] boolValue];
                
                if (adsEnabled) {
                    NSArray *frequencyLimits = [HZDictionaryUtils objectForKey:@"frequency_limits" ofClass:[NSArray class] default:@[] dict:options];
                    
                    for (NSDictionary *frequencyLimitOptions in frequencyLimits) {
                        NSTimeInterval timeInterval = [[HZDictionaryUtils objectForKey:@"seconds" ofClass:[NSNumber class] default:@0 dict:frequencyLimitOptions] doubleValue];
                        NSUInteger impressionLimit = [[HZDictionaryUtils objectForKey:@"ads_quantity" ofClass:[NSNumber class] default:@0 dict:frequencyLimitOptions] unsignedIntegerValue];
                        
                        HZCreativeType creativeType = hzCreativeTypeFromNSNumber([HZDictionaryUtils objectForKey:@"ad_format" ofClass:[NSNumber class] default:@(HZCreativeTypeUnknown) dict:frequencyLimitOptions]);
                        
                        HZSegmentationFrequencyLimitRule *freqRule = [[HZSegmentationFrequencyLimitRule alloc] init];
                        freqRule.auctionType = auctionType;
                        freqRule.timeInterval = timeInterval;
                        freqRule.impressionLimit = impressionLimit;
                        freqRule.adsEnabled = YES;
                        freqRule.creativeType = creativeType;
                        [frequencyRules addObject:freqRule];
                    }
                } else {
                    // ads disabled for this auctionType & all creativeTypes - the frequency limits don't matter / might not even be provided by the server.
                    HZSegmentationFrequencyLimitRule *freqRule = [[HZSegmentationFrequencyLimitRule alloc] init];
                    freqRule.auctionType = auctionType;
                    freqRule.timeInterval = 0;
                    freqRule.impressionLimit = 0;
                    freqRule.adsEnabled = NO;
                    freqRule.creativeType = HZCreativeTypeUnknown; // all creativeTypes
                    [frequencyRules addObject:freqRule];
                }
            } else {
                HZILog(@"Segmentation received a ruleType that is unsupported by this version of the SDK: '%@'. It will be ignored.", ruleType);
            }
        }
        
        [loadedSegments addObject:[[HZSegmentationSegment alloc] initWithTags:tags disabledNetworks:disabledNetworks placementIDOverrides:placementIDOverrides frequencyLimitRules:frequencyRules name:name]];
    }
    
    self.segments = [NSSet setWithArray:loadedSegments];
    
    // send segments off to retrieve their persisted impression history
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
        HZDLog(@"HZSegmentationController: Active segments for this user: \n========================================\n\n%@\n========================================\n", [[self.segments allObjects] componentsJoinedByString:@"\n----------------------------------------\n\n"]);
        if (completion) {
            dispatch_async(dispatch_get_main_queue() , ^{
                completion(YES);
            });
        }
    });
}


#pragma mark - Query

- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter withMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    
    return [adapter hasAdWithMetadata:dataProvider] && [self allowAdapter:adapter toShowAdWithMetadata:dataProvider];
}

- (BOOL) allowAdapter:(nonnull HZBaseAdapter *)adapter toShowAdWithMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    if (!self.enabled) {
        return YES;
    }
    
    __block BOOL didGetLimited = NO;
    [self.segments enumerateObjectsUsingBlock:^(HZSegmentationSegment *segment, BOOL *stop) {
        if([segment limitsImpressionWithCreativeType:dataProvider.creativeType adapter:adapter tag:dataProvider.tag]) {
            //HZDLog(@"HZSegmentation: ad not allowed for type: %@, adapter: %@, tag: %@. First segment limiting impression: %@", NSStringFromCreativeType(dataProvider.creativeType), adapter, dataProvider.tag, segment);
            didGetLimited = YES;
            *stop = YES;
        }
    }];
    
    return !didGetLimited;
}

- (nullable NSString *) placementIDOverrideForAdapter:(nonnull HZBaseAdapter *)adapter tag:(nonnull NSString *)tag creativeType:(HZCreativeType)creativeType {
    if (!self.enabled) {
        return nil;
    }
    
    __block NSString *retVal = nil;
    [self.segments enumerateObjectsUsingBlock:^(HZSegmentationSegment *segment, BOOL *stop) {
        if ([segment appliesToRequestWithTag:tag]) {
            
            NSString * placementID = [HZDictionaryUtils objectForKey:NSStringFromCreativeType(creativeType) ofClass:[NSString class] default:nil dict:[HZDictionaryUtils objectForKey:[adapter name] ofClass:[NSDictionary class] default:@{} dict:segment.placementIDOverrides]];
            if (retVal) {
                HZELog(@"Mutliple segments applying placement ID overrides to this request with '%@' adapter for tag '%@'. Overwriting already-parsed placement ID override '%@' with new one: '%@'.", [adapter name], tag, retVal, placementID);
            }
            retVal = placementID;
        }
    }];
    
    return retVal;
}


#pragma mark - Report

- (void) recordImpressionWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag adapter:(nonnull HZBaseAdapter *)adapter {
    if (!self.enabled) {
        return;
    }
    
    NSDate *date = [NSDate date];
    for(HZSegmentationSegment *segment in self.segments) {
        [segment recordImpressionWithCreativeType:creativeType adapter:adapter tag:tag date:date];
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
    if ([[adapter name] isEqualToString:[HZCrossPromoAdapter name]]) {
        return HZAuctionTypeCrossPromo;
    } else {
        return HZAuctionTypeMonetization;
    }
}

+ (HZAuctionType) auctionTypeFromAuctionTypeString:(NSString *)auctionTypeString {
    if ([auctionTypeString isEqualToString:RULETYPE_CROSSPROMO_ADS_FREQUENCY]) {
        return HZAuctionTypeCrossPromo;
    } else if([auctionTypeString isEqualToString:RULETYPE_MONETIZING_ADS_FREQUENCY]) {
        return HZAuctionTypeMonetization;
    }
    
    HZELog(@"HZSegmentationController: unregcognized auctionType string: %@. Processing it as HZAuctionTypeMonetization.", auctionTypeString);
    return HZAuctionTypeMonetization;
}


@end