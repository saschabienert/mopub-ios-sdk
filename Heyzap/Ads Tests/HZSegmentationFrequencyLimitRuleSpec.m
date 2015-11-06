//
//  HZSegmentationFrequencyLimitRuleSpec.m
//  Heyzap
//
//  Created by Monroe Ekilah on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZSegmentationController.h"
#import "HZSegmentationSegment.h"
#import "HZImpressionHistory.h"
#import "HZHeyzapAdapter.h"
#import "HZCrossPromoAdapter.h"

@interface HZSegmentationFrequencyLimitRule (Testing)

@property (nonatomic) BOOL isLoaded; // whether or not the frequency limit has loaded its impression history from HZImpressionHistory yet
@property (atomic, nullable) NSMutableOrderedSet<NSDate *> *impressionHistory; // ordered set of timestamps at which impressions fitting this segment's search criteria occured, most recent first. atomic since `loadWithDb:` can be called on any thread, as can the methods that access this property

- (NSUInteger) impressionCount;
- (nonnull NSArray<NSString *> *) adTags;
@end

SPEC_BEGIN(HZSegmentationFrequencyLimitRuleSpec)


#define FREQUENCYLIMIT_TIME_INTERVAL .5

describe(@"HZSegmentationFrequencyLimitRule", ^{
    
    __block HZSegmentationFrequencyLimitRule *frequencyLimitRule;
    __block HZSegmentationSegment *parentSegmentMock;
    
    __block HZBaseAdapter *mockAdapter;
    
    NSArray <NSString *> *const expectedAdTags = @[@"test tag whatever"];
    
    HZCreativeType const expectedCreativeType = HZCreativeTypeStatic;
    HZCreativeType const wrongCreativeType = HZCreativeTypeVideo;
    HZCreativeType const allCreativeTypes = HZCreativeTypeUnknown;
    
    HZAuctionType const expectedAuctionType= HZAuctionTypeMonetization;
    HZAuctionType const allAuctionTypes = HZAuctionTypeMixed;
    
    beforeAll(^{
        // parent segment should only be used to access tags. "null mocks" throw exceptions for unstubbed/unmocked methods.
        parentSegmentMock = [KWMock nullMockForClass:[HZSegmentationSegment class]];
        [parentSegmentMock stub:@selector(adTags) andReturn:expectedAdTags];
    });
    
    beforeEach(^{
        mockAdapter = [HZHeyzapAdapter sharedAdapter]; // not xpromo
        
        frequencyLimitRule = [[HZSegmentationFrequencyLimitRule alloc] init];
        frequencyLimitRule.creativeType = expectedCreativeType;
        frequencyLimitRule.auctionType = expectedAuctionType;
        frequencyLimitRule.timeInterval = FREQUENCYLIMIT_TIME_INTERVAL;
        frequencyLimitRule.parentSegment = parentSegmentMock;
        frequencyLimitRule.impressionLimit = NSUIntegerMax;
        frequencyLimitRule.adsEnabled = YES;
        
        frequencyLimitRule.impressionHistory = [[NSMutableOrderedSet alloc] init];
    });
    
    it(@"Initializes with good default values", ^{
        frequencyLimitRule = [[HZSegmentationFrequencyLimitRule alloc] init];
        [[theValue(frequencyLimitRule.creativeType) should] equal:theValue(allCreativeTypes)];
        [[[frequencyLimitRule parentSegment] should] beNil];
        [[[frequencyLimitRule adTags] should] equal:@[]];//parent unset, empty should be default
        [[theValue(frequencyLimitRule.impressionLimit) should] equal:theValue(NSUIntegerMax)];
        [[theValue(frequencyLimitRule.auctionType) should] equal:theValue(allAuctionTypes)];
        [[theValue(frequencyLimitRule.adsEnabled) should] equal:theValue(YES)];
        [[frequencyLimitRule.impressionHistory should] beNil];
        [[theValue(frequencyLimitRule.isLoaded) should] equal:theValue(NO)];
    });
    
    it(@"Loads from the HZImpressionHistory correctly", ^{
        NSDate *const date = [NSDate dateWithTimeInterval:-5 sinceDate:[NSDate date]];
        NSDate *const date2 = [NSDate dateWithTimeInterval:1 sinceDate:date];
        NSArray <NSDate *> * array = @[date, date2];
        HZImpressionHistory *impressionHistoryMock = [KWMock mockForClass:[HZImpressionHistory class]];
        
        [[HZImpressionHistory should] receive:@selector(sharedInstance) andReturn:impressionHistoryMock];
        [[impressionHistoryMock should] receive:@selector(impressionsSince:withCreativeType:tags:auctionType:databaseConnection:mostRecentFirst:) andReturn:[[NSMutableOrderedSet alloc] initWithArray:array] withCount:1 arguments:any(), theValue(expectedCreativeType), any(), theValue(expectedAuctionType), any(), theValue(YES)];
        
        frequencyLimitRule.impressionHistory = nil;
        frequencyLimitRule.timeInterval = 600; // since `[frequencyLimitRule impressionCount]` prunes the segments if they're old, make sure the test has time to run
        
        [frequencyLimitRule loadWithDb:(sqlite3 *)impressionHistoryMock]; // use pointer to mock as db pointer since it won't be used but can't be nil
        for(NSDate *d in frequencyLimitRule.impressionHistory) {
            [[d should] beBetween:date and:date2];
        }
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue([array count])];
    });
    
    it(@"Does not limit impressions if not loaded from the db yet, unless ads are disabled globally for the auctionType or the limit is 0", ^{
        
        frequencyLimitRule.impressionHistory = nil; // simulate "not loaded"
        frequencyLimitRule.impressionLimit = 0;
        
        [[theValue(frequencyLimitRule.isLoaded) should] equal:theValue(NO)];
        
        BOOL limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)]; // limit is 0, should still limit impression even though not loaded
        
        frequencyLimitRule.impressionLimit = 1;
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)]; // limit is 1, should not limit impression since not loaded
        
        frequencyLimitRule.adsEnabled = NO;
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)]; // ads disabled, should still limit impression even though not loaded & cap not hit
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)]; // creativeType shouldn't matter either since ads disabled (applies to all creatveTypes)
    });
    
    it(@"Limits an impression with matching creativeType and auctionType-matching adapter", ^{
        frequencyLimitRule.impressionLimit = 0;
        BOOL limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
    });
    
    it(@"Does not limit impression with mismatch on creativeType", ^{
        BOOL limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit impression with mismatch on auctionType", ^{
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        
        BOOL limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit impression with mismatch on auctionType AND creativeType", ^{
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        
        BOOL limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Adds impression to history that matches creativeType and auctionType-matching adapter", ^{
        NSDate *const date = [NSDate date];
        
        BOOL recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue(1)];
        [[theValue(frequencyLimitRule.impressionHistory.count) should] equal:theValue(1)];
        for(NSDate *d in frequencyLimitRule.impressionHistory) {
            [[d should]equal:date];
        }
    });
    
    it(@"Adds impression to history that matches creativeType, no auctionType filter", ^{
        NSDate *const date = [NSDate dateWithTimeInterval:-5 sinceDate:[NSDate date]];
        NSDate *const date2 = [NSDate dateWithTimeInterval:1 sinceDate:date];
        frequencyLimitRule.auctionType = allAuctionTypes;
        frequencyLimitRule.timeInterval = 600; // since `[frequencyLimitRule impressionCount]` prunes the segments if they're old, make sure the test has time to run
        
        BOOL recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date2];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue(2)];
        [[theValue(frequencyLimitRule.impressionHistory.count) should] equal:theValue(2)];
        for(NSDate *d in frequencyLimitRule.impressionHistory) {
            [[d should] beBetween:date and:date2];
        }
    });
    
    it(@"Adds impression to history that matches auctionType-matching adapter, no creativeType filter", ^{
        NSDate *const date = [NSDate dateWithTimeInterval:-5 sinceDate:[NSDate date]];
        NSDate *const date2 = [NSDate dateWithTimeInterval:1 sinceDate:date];
        frequencyLimitRule.creativeType = allCreativeTypes;
        frequencyLimitRule.timeInterval = 600; // since `[frequencyLimitRule impressionCount]` prunes the segments if they're old, make sure the test has time to run
        
        BOOL recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        recorded = [frequencyLimitRule recordImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter date:date2];
        [[theValue(recorded) should] equal:theValue(YES)];
        
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue(2)];
        [[theValue(frequencyLimitRule.impressionHistory.count) should] equal:theValue(2)];
        for(NSDate *d in frequencyLimitRule.impressionHistory) {
            [[d should] beBetween:date and:date2];
        }
    });
    
    it(@"Does not add impression to history that does not match creativeType or auctionType (or both)", ^{
        NSDate *const date = [NSDate date];
        
        BOOL recorded = [frequencyLimitRule recordImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        
        recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        recorded = [frequencyLimitRule recordImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        [[theValue(frequencyLimitRule.impressionHistory.count) should] equal:theValue(0)];
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue(0)];
    });
    
    it(@"Does not add impression to history when disabled or not loaded.", ^{
        NSDate *const date = [NSDate date];
        frequencyLimitRule.creativeType = allCreativeTypes;
        frequencyLimitRule.auctionType = allAuctionTypes;
        
        frequencyLimitRule.adsEnabled = NO;
        BOOL recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        frequencyLimitRule.adsEnabled = YES;
        frequencyLimitRule.impressionHistory = nil;
        recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(NO)];
        
        [[theValue(frequencyLimitRule.impressionHistory.count) should] equal:theValue(0)];
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue(0)];
    });
    
    it(@"Impression limit works with an impression stored, expires only after time limit", ^{
        NSDate *const date = [NSDate date];
        frequencyLimitRule.impressionLimit = 1;
        
        // not limited prior to impression
        BOOL limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
        
        // store impression
        BOOL recorded = [frequencyLimitRule recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter date:date];
        [[theValue(recorded) should] equal:theValue(YES)]; // just checking
        
        // limited directly after impression
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue(1)];
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        for(NSDate *d in frequencyLimitRule.impressionHistory) {
            [[d should]equal:date];
        }
        
        // wait longer than interval for impression to expire
        [NSThread sleepForTimeInterval:(FREQUENCYLIMIT_TIME_INTERVAL*1.5)];
        
        // no longer limited
        [[theValue([frequencyLimitRule impressionCount]) should] equal:theValue(0)];
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
        
    });
    
    it(@"Limits an impression no matter what the creativeType when ads are disabled, unless adapter's auctionType is a mismatch", ^{
        frequencyLimitRule.adsEnabled = NO;

        // frequencyLimitRule cares about creativeTypes and auctionTypes
        BOOL limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        // this one is important - the creative type can be a mismatch, the impression should be limited still as long as the auction type matches
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
        
        
        // now frequencyLimitRule doesn't care about creativeTypes
        // only auctionType matches should limit impressions
        frequencyLimitRule.creativeType = allCreativeTypes;
        mockAdapter = [HZHeyzapAdapter sharedAdapter];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(NO)];
        
        // now frequencyLimitRule doesn't care about creativeTypes OR auctionTypes
        // all impressions should be limited
        frequencyLimitRule.creativeType = allCreativeTypes;
        frequencyLimitRule.auctionType = allAuctionTypes;
        mockAdapter = [HZHeyzapAdapter sharedAdapter];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        
        // now frequencyLimitRule doesn't care about auctionTypes, but does care about creativeType
        // normally only creativeType mismatch should limit impressions, but since ads are disabled globally, the frequencyLimitRule should also ignore creativeType
        frequencyLimitRule.creativeType = expectedCreativeType;
        frequencyLimitRule.auctionType = allAuctionTypes;
        mockAdapter = [HZHeyzapAdapter sharedAdapter];
        
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];

        // this one is important - the creative type can be a mismatch, the impression should be limited still as long as the auction type matches (and we don't care about auctionType in this part of the test)
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        mockAdapter = [HZCrossPromoAdapter sharedAdapter];
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];
        
        // this one is important - the creative type can be a mismatch, the impression should be limited still as long as the auction type matches (and we don't care about auctionType in this part of the test)
        limited = [frequencyLimitRule limitsImpressionWithCreativeType:wrongCreativeType adapter:mockAdapter];
        [[theValue(limited) should] equal:theValue(YES)];

    });

});

SPEC_END