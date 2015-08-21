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
@property (nonatomic) HZCreativeType creativeType;
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
    
    __block HZCreativeType const expectedCreativeType = HZCreativeTypeStatic;
    __block HZCreativeType const wrongCreativeType = HZCreativeTypeVideo;
    __block HZCreativeType const allCreativeTypes = HZCreativeTypeUnknown; // todo test
    
    __block HZAuctionType const expectedAuctionType= HZAuctionTypeMonetization;
    __block HZAuctionType const wrongAuctionType = HZAuctionTypeCrossPromo;
    
    __block HZImpressionHistory *impressionHistoryMock;
    
    beforeAll(^{
        impressionHistoryMock = [KWMock mockForClass:[HZImpressionHistory class]];
    });
    
    beforeEach(^{
        segment = [[HZSegmentationSegment alloc] initWithTimeInterval:SEGMENT_TIME_INTERVAL forTags:nil creativeType:expectedCreativeType auctionType:expectedAuctionType limit:0 adsEnabled:YES];
        segment.impressionHistory = [[NSMutableOrderedSet alloc] init];
    });
    
    afterEach(^{
        
    });
    
    it(@"Loads from the HZImpressionHistory correctly", ^{
        
        NSArray * array = @[[NSDate date]];
        
        [[HZImpressionHistory should] receive:@selector(sharedInstance) andReturn:impressionHistoryMock];
        [[impressionHistoryMock should] receive:@selector(impressionsSince:withCreativeType:tags:auctionType:databaseConnection:mostRecentFirst:) andReturn:[[NSMutableOrderedSet alloc] initWithArray:array] withCount:1 arguments:any(), theValue(expectedCreativeType), any(), theValue(expectedAuctionType), any(), theValue(YES)];
        
        segment.impressionHistory = nil;
        [segment loadWithDb:(sqlite3 *)impressionHistoryMock]; // use pointer to mock as db pointer since it won't be used but can't be nil
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
    });
    
    it(@"Limits an impression with matching creativeType and auctionType, no tag filter", ^{
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:@"any tag"];
        
        [[theValue(limited) should] equal:theValue(YES)];
    });
    
    it(@"Limits an impression only with a matching tag when creativeType and auctionType match", ^{
        segment.adTags = @[tag, other_tag];
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:other_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit impression with mismatch on creativeType", ^{
        BOOL limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:@"any tag"];
        
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit impression with mismatch on auctionType", ^{
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:@"any tag"];
        
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Adds impression to history that matches creativeType and auctionType, no tag filter", ^{
        NSDate *const date = [NSDate date];
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
        [[theValue(segment.impressionHistory.count) should] equal:theValue(1)];
        for(NSDate *d in segment.impressionHistory) {
            [[d should]equal:date];
        }
    });
    
    it(@"Does not add impression to history that does not match creativeType or auctionType, no tag filter", ^{
        NSDate *const date = [NSDate date];
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:@"whatever tag" date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        recorded = [segment recordImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:@"whatever tagz" date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        recorded = [segment recordImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:@"whatever tag man" date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        [[theValue(segment.impressionHistory.count) should] equal:theValue(0)];
        [[theValue([segment impressionCount]) should] equal:theValue(0)];
    });
    
    it(@"Adds impression to history that matches creativeType and auctionType with tag filter", ^{
        NSDate *const date = [NSDate date];
        segment.adTags = @[tag, other_tag];
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
        [[theValue(segment.impressionHistory.count) should] equal:theValue(1)];
        for(NSDate *d in segment.impressionHistory) {
            [[d should]equal:date];
        }
    });
    
    it(@"Does not add impression to history that matches creativeType and auctionType but not tag filter", ^{
        NSDate *const date = [NSDate date];
        segment.adTags = @[tag, other_tag];
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:not_matching_tag date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        [[theValue([segment impressionCount]) should] equal:theValue(0)];
        [[theValue(segment.impressionHistory.count) should] equal:theValue(0)];
    });
    
    it(@"Impression limit works with an impression stored, expires only after time limit", ^{
        NSDate *const date = [NSDate date];
        segment.impressionLimit = 1;
        
        // not limited prior to impression
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        // store impression
        [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag date:date];
        
        // limited directly after impression
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        // wait for impression to exist for half it's lifetime
        [NSThread sleepForTimeInterval:(SEGMENT_TIME_INTERVAL / 2)];
        
        // limited after some time still
        [[theValue([segment impressionCount]) should] equal:theValue(1)];
        for(NSDate *d in segment.impressionHistory) {
            [[d should]equal:date];
        }
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        // wait for impression to expire
        [NSThread sleepForTimeInterval:(SEGMENT_TIME_INTERVAL / 2)];
        
        // no longer limited
        [[theValue([segment impressionCount]) should] equal:theValue(0)];
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
    });
    
    it(@"Limits an impression no matter what the creativeType when ads are disabled, unless tag or auctionType mismatch", ^{
        segment.adTags = @[tag, other_tag];
        segment.adsEnabled = NO;
        
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:other_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        // this one is important - the creative type can be a mismatch, the impression should be limited still as long as the auction type and tag match
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        // again, but now segment applies to all tags, so only an auctionType mismatch should allow impressions
        segment.adTags = nil;
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:other_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        
        // same expectations as 2nd test above, but now segment doesn't care about creativeTypes
        segment.creativeType = allCreativeTypes;
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:other_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Limits an impression with matching auctionType, no tag filter, no creativeType filter", ^{
        segment.creativeType = allCreativeTypes;
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:@"any tag"];
        [[theValue(limited) should] equal:theValue(YES)];
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:@"any other tag"];
        [[theValue(limited) should] equal:theValue(YES)];
    });
    
    it(@"Limits an impression only with a matching tag when auctionType matches, no creativeType filter", ^{
        segment.adTags = @[tag, other_tag];
        segment.creativeType = allCreativeTypes;
        
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:other_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:other_tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit impression with mismatch on auctionType, no creativeType filter", ^{
        segment.creativeType = allCreativeTypes;
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:@"any tag"];
        [[theValue(limited) should] equal:theValue(NO)];
        limited = [segment limitsImpressionWithCreativeType:wrongCreativeType auctionType:wrongAuctionType tag:@"any other tag"];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Adds impression to history that matches auctionType, no tag filter or creativeType filter", ^{
        NSDate *const date = [NSDate date];
        NSDate *const date2 = [NSDate date];
        segment.creativeType = allCreativeTypes;
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        recorded = [segment recordImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:tag date:date2];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        [[theValue([segment impressionCount]) should] equal:theValue(2)];
        [[theValue(segment.impressionHistory.count) should] equal:theValue(2)];
        for(NSDate *d in segment.impressionHistory) {
            [[d should] beBetween:date and:date2];
        }
    });
    
    it(@"Does not add impression to history that does not match auctionType, no tag filter or creativeType filter", ^{
        NSDate *const date = [NSDate date];
        segment.creativeType = allCreativeTypes;
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:wrongAuctionType tag:@"whatever tag" date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        [[theValue(segment.impressionHistory.count) should] equal:theValue(0)];
        [[theValue([segment impressionCount]) should] equal:theValue(0)];
    });
    
    it(@"Adds impression to history that matches auctionType with tag filter, no creativeType filter", ^{
        NSDate *const date = [NSDate date];
        NSDate *const date2 = [NSDate date];
        segment.adTags = @[tag, other_tag];
        segment.creativeType = allCreativeTypes;
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType auctionType:expectedAuctionType tag:tag date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        recorded = [segment recordImpressionWithCreativeType:wrongCreativeType auctionType:expectedAuctionType tag:tag date:date2];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        [[theValue([segment impressionCount]) should] equal:theValue(2)];
        [[theValue(segment.impressionHistory.count) should] equal:theValue(2)];
        for(NSDate *d in segment.impressionHistory) {
           [[d should] beBetween:date and:date2];
        }
    });
    
});

SPEC_END
