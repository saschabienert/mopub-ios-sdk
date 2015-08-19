//
//  HZSegmentationSegmentSpec.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/18/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZSegmentationSegment.h"
#import "HZImpressionHistory.h"

@interface HZSegmentationSegment (Testing)

@property (nonatomic) NSTimeInterval timeInterval; // number of seconds back the segment should look for impressions that fit the  parameters defined below
@property (nonatomic) HZAdType adType;
@property (nonatomic, nullable) NSArray * adTags; // nil == applies to any tag
@property (nonatomic) NSUInteger impressionLimit;
@property (nonatomic) HZAuctionType auctionType;
@property (nonatomic) BOOL adsEnabled; // ignore the limit & interval - on/off switch for ads with the specified type/tag/auctionType

@property (nonatomic) BOOL isLoaded; // whether or not the segment has loaded it's history from HZImpressionHistory yet
@property (nonatomic, nullable) NSMutableOrderedSet *impressionHistory; // ordered set of timestamps at which impressions fitting this segment's search criteria occured, most

- (NSUInteger) impressionCount;

@end

SPEC_BEGIN(HZSegmentationSegmentSpec)

#define SEGMENT_TIME_INTERVAL 0.2

describe(@"HZSegmentationSegment", ^{
    __block HZSegmentationSegment *segment;
    
    __block NSString *const tag = @"limited tag";
    __block NSString *const other_tag = @"other tag!";
    __block NSString *const not_matching_tag = @"not filtered out";
    
    beforeEach(^{
        segment = [[HZSegmentationSegment alloc] initWithTimeInterval:SEGMENT_TIME_INTERVAL forTags:nil adType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization limit:0 adsEnabled:YES];
        segment.impressionHistory = [[NSMutableOrderedSet alloc] init];
    });
    
    afterEach(^{
        
    });
    
    // TODO add tests for adsEnabled
    // TODO add tests for 
    
    it(@"Loads from the HZImpressionHistory correctly", ^{
        HZImpressionHistory *impressionHistoryMock = [KWMock mockForClass:[HZImpressionHistory class]];
        NSArray * array = @[[NSDate date]];
        
        [[HZImpressionHistory should] receive:@selector(sharedInstance) andReturn:impressionHistoryMock];
        [[impressionHistoryMock should] receive:@selector(impressionsSince:withType:tags:auctionType:databaseConnection:mostRecentFirst:) andReturn:[[NSMutableOrderedSet alloc] initWithArray:array] withCount:1 arguments:any(), theValue(HZAdTypeInterstitial), any(), theValue(HZAuctionTypeMonetization), any(), theValue(YES)];
        
        segment.impressionHistory = nil;
        [segment loadWithDb:(sqlite3 *)impressionHistoryMock]; // use pointer to mock as db pointer since it won't be used but can't be nil
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
    });
    
    it(@"Limits an impression with matching adType and auctionType, no tag filter", ^{
        BOOL limited = [segment limitsImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:@"any tag"];
        
        [[theValue(limited) should] equal:theValue(YES)];
    });
    
    it(@"Limits an impression with only matching tags when adType and auctionType match", ^{
        segment.adTags = @[tag, other_tag];
        BOOL limited = [segment limitsImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:other_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit impression with mismatch on adType", ^{
        BOOL limited = [segment limitsImpressionWithAdType:HZAdTypeIncentivized auctionType:HZAuctionTypeMonetization tag:@"any tag"];
        
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit impression with mismatch on auctionType", ^{
        BOOL limited = [segment limitsImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeCrossPromo tag:@"any tag"];
        
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Adds impression to history that matches adType and auctionType, no tag filter", ^{
        NSDate *const date = [NSDate date];
        
        BOOL recorded = [segment recordImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:@"whatever tag" date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        [[theValue(segment.impressionHistory.count) should] equal:theValue(1)];
        for(NSDate *d in segment.impressionHistory) {
            [[d should]equal:date];
        }
    });
    
    it(@"Does not add impression to history that does not match adType or auctionType, no tag filter", ^{
        NSDate *const date = [NSDate date];
        
        BOOL recorded = [segment recordImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeCrossPromo tag:@"whatever tag" date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        recorded = [segment recordImpressionWithAdType:HZAdTypeIncentivized auctionType:HZAuctionTypeMonetization tag:@"whatever tagz" date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        recorded = [segment recordImpressionWithAdType:HZAdTypeIncentivized auctionType:HZAuctionTypeCrossPromo tag:@"whatever tag man" date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        [[theValue(segment.impressionHistory.count) should] equal:theValue(0)];
    });
    
    it(@"Adds impression to history that matches adType and auctionType with tag filter", ^{
        NSDate *const date = [NSDate date];
        segment.adTags = @[tag, other_tag];
        
        BOOL recorded = [segment recordImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:tag date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        [[theValue(segment.impressionHistory.count) should] equal:theValue(1)];
        for(NSDate *d in segment.impressionHistory) {
            [[d should]equal:date];
        }
    });
    
    it(@"Does not add impression to history that matches adType and auctionType but not tag filter", ^{
        NSDate *const date = [NSDate date];
        segment.adTags = @[tag, other_tag];
        
        BOOL recorded = [segment recordImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:not_matching_tag date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        [[theValue(segment.impressionHistory.count) should] equal:theValue(0)];
    });
    
    it(@"Impression limit expires only after time limit", ^{
        NSDate *const date = [NSDate date];
        
        [segment recordImpressionWithAdType:HZAdTypeInterstitial auctionType:HZAuctionTypeMonetization tag:@"whatever tag" date:date];
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
        
        [NSThread sleepForTimeInterval:(SEGMENT_TIME_INTERVAL / 2)];
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
        
        [NSThread sleepForTimeInterval:(SEGMENT_TIME_INTERVAL / 2)];
        [[theValue([segment impressionCount]) should] equal:theValue(0)];
        
    });
    
});

SPEC_END
