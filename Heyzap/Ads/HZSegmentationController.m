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
//    HZSegmentationSegment *s1 = [[HZSegmentationSegment alloc] initWithTimeInterval:90 forTags:@[@"default"] adType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization limit:1];
//    HZSegmentationSegment *s2 = [[HZSegmentationSegment alloc] initWithTimeInterval:90 forTags:@[@"on"] adType:HZAdTypeVideo auctionType:HZAuctionTypeMonetization limit:1];
//    HZSegmentationSegment *s3 = [[HZSegmentationSegment alloc] initWithTimeInterval:90 forTags:nil adType:HZAdTypeIncentivized auctionType:HZAuctionTypeMonetization limit:1];
//    HZSegmentationSegment *s4 = [[HZSegmentationSegment alloc] initWithTimeInterval:60 forTags:nil adType:HZAdTypeBanner auctionType:HZAuctionTypeMonetization limit:1];
//    self.segments = [NSSet setWithArray:@[s1, s2, s3, s4]];
    
    NSMutableArray * loadedSegments = [[NSMutableArray alloc] init];
    
    NSArray * segmentsResponse = [HZDictionaryUtils hzObjectForKey:@"segments" ofClass:[NSArray class] default:@[] withDict:startDictionary];
    for (NSDictionary *segmentDict in segmentsResponse) {
        if([loadedSegments count] == 2) break; // remove once server dupes are gone
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
                    
                    // ad_format = 0 means all adTypes. otherwise, it's a numerical enum value from the server describing the format
                    NSUInteger adTypeServerEnum = [[HZDictionaryUtils hzObjectForKey:@"ad_format" ofClass:[NSNumber class] default:@0 withDict:frequencyLimitOptions] unsignedIntegerValue];
                    BOOL specificAdType = (adTypeServerEnum != 0);
                    HZAdType adType = HZAdTypeInterstitial; //(HZAdType)adTypeServerEnum; // TODO actually convert this enum to an adType later, server is sending down a creative type enum
                    
                    [loadedSegments addObject:[[HZSegmentationSegment alloc] initWithTimeInterval:timeInterval forTags:tags adType:(specificAdType ? &adType : NULL) auctionType:auctionType limit:impressionLimit adsEnabled:adsEnabled]];
                }
            } else {
                // ads disabled - there might not be any frequency limits.
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

- (BOOL) bannerAdapterHasAllowedAd:(nonnull HZBannerAdapter *)adapter forType:(HZAdType)adType tag:(nonnull NSString *)adTag {
    return [adapter isAvailable] && [self isAdAllowedForType:HZAdTypeBanner auctionType:[HZSegmentationController auctionTypeForAdapter:adapter.parentAdapter] tag:adTag];
}

- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter forType:(HZAdType)adType tag:(nonnull NSString *)adTag {
    return [adapter hasAdForType:adType] && [self isAdAllowedForType:adType auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] tag:adTag];
}

- (BOOL) isAdAllowedForType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)adTag {
    __block BOOL didGetLimited = NO;
    [self.segments enumerateObjectsUsingBlock:^(HZSegmentationSegment *segment, BOOL *stop) {
        if([segment limitsImpressionWithAdType:adType auctionType:auctionType tag:adTag]) {
            HZDLog(@"HZSegmentation: ad not allowed for type: %@, auctionType: %@, tag: %@. First segment limiting impression: %@", NSStringFromAdType(adType), NSStringFromHZAuctionType(auctionType), adTag, segment);
            didGetLimited = YES;
            *stop = YES;
        }
    }];
    
    return !didGetLimited;
}


#pragma mark - Report

- (void) recordImpressionWithType:(HZAdType)adType tag:(nonnull NSString *)tag adapter:(nonnull HZBaseAdapter *)adapter {
    NSDate *date = [NSDate date];
    for(HZSegmentationSegment *segment in self.segments) {
        [segment recordImpressionWithAdType:adType auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] tag:tag date:date];
    }
    
    [[HZImpressionHistory sharedInstance] recordImpressionWithType:adType tag:tag auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] date:date];
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
    
    HZELog(@"HZSegmentationController: unregcognized auctionType string from server: %@. Processing it as HZAuctionTypeMonetization.", auctionTypeString);
    return HZAuctionTypeMonetization;
}


@end