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

@interface HZSegmentationController()
@property (nonnull, nonatomic) NSMutableSet *segments;

@end

@implementation HZSegmentationController

- (nullable instancetype) init {
    self = [super init];
    if (self) {
        _segments = [[NSMutableSet alloc] init];
    }
    
    return self;
}

+ (HZAuctionType) auctionTypeForAdapter:(nonnull HZBaseAdapter *)adapter {
    return [adapter class] == [HZCrossPromoAdapter class] ? HZAuctionTypeCrossPromo : HZAuctionTypeMonetization;
}

- (void) setupFromMediationStart:(nonnull NSDictionary *)startDictionary {
    HZSegmentationSegment *s1 = [[HZSegmentationSegment alloc] initWithTimeInterval:90 forTags:@[@"on"] adType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization limit:1];
    HZSegmentationSegment *s2 = [[HZSegmentationSegment alloc] initWithTimeInterval:90 forTags:@[@"default"] adType:HZAdTypeVideo auctionType:HZAuctionTypeMonetization limit:1];
    HZSegmentationSegment *s3 = [[HZSegmentationSegment alloc] initWithTimeInterval:90 forTags:nil adType:HZAdTypeIncentivized auctionType:HZAuctionTypeMonetization limit:1];
    HZSegmentationSegment *s4 = [[HZSegmentationSegment alloc] initWithTimeInterval:60 forTags:nil adType:HZAdTypeBanner auctionType:HZAuctionTypeMonetization limit:1];
    self.segments = [NSMutableSet setWithArray:@[s1, s2, s3, s4]];
    HZDLog(@"Active segments for this user: %@", self.segments);
    
}

- (BOOL) bannerAdapterHasAllowedAd:(nonnull HZBannerAdapter *)adapter forType:(HZAdType)adType tag:(nonnull NSString *)adTag {
    return [adapter isAvailable] && [self isAdAllowedForType:HZAdTypeBanner auctionType:[HZSegmentationController auctionTypeForAdapter:adapter.parentAdapter] tag:adTag];
}

- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter forType:(HZAdType)adType tag:(nonnull NSString *)adTag {
    return [adapter hasAdForType:adType] && [self isAdAllowedForType:adType auctionType:[HZSegmentationController auctionTypeForAdapter:adapter] tag:adTag];
}

- (BOOL) isAdAllowedForType:(HZAdType)adType auctionType:(HZAuctionType)auctionType tag:(nonnull NSString *)adTag {
    __block BOOL didGetLimitied = NO;
    [self.segments enumerateObjectsUsingBlock:^(HZSegmentationSegment *segment, BOOL *stop) {
        if([segment limitsImpressionWithAdType:adType auctionType:auctionType tag:adTag]) {
            HZDLog(@"HZSegmentation: ad not allowed for type: %@, auctionType: %@, tag: %@. Segment limiting impression: %@", NSStringFromAdType(adType), NSStringFromHZAuctionType(auctionType), adTag, segment);
            didGetLimitied = YES;
            *stop = YES;
        }
    }];
    
    return !didGetLimitied;
}

- (BOOL) recordImpressionWithType:(HZAdType)adType andTag:(nonnull NSString *)tag fromAdapter:(nonnull HZBaseAdapter *)adapter {
    return [[HZImpressionHistory sharedInstance] recordImpressionWithType:adType andTag:tag andAuctionType:[HZSegmentationController auctionTypeForAdapter:adapter]];
}

@end