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
#import "HZSegmentationFrequencyLimitRule.h"
#import "HZCreativeType.h"
#import "HZBaseAdapter.h"

@interface HZSegmentationSegment (Testing)

@property (nonatomic, nonnull) NSArray<NSString *> *adTags;
@property (nonatomic, nonnull) NSArray<NSString *> *disabledNetworks;

@property (nonatomic, nonnull) NSArray<HZSegmentationFrequencyLimitRule *> *frequencyLimitRules;

@property (nonatomic, nonnull) NSDictionary <NSString *, NSString *>* placementIDOverrides;



@end

SPEC_BEGIN(HZSegmentationSegmentSpec)

#define SEGMENT_TIME_INTERVAL .5

describe(@"HZSegmentationSegment", ^{
    __block HZSegmentationSegment *segment;
    __block HZSegmentationFrequencyLimitRule *ruleMock1;
    __block HZSegmentationFrequencyLimitRule *ruleMock2;
    __block HZBaseAdapter *mockAdapter;
    
    NSString *const tag = @"limited tag";
    NSString *const other_tag = @"other tag!";
    NSString *const not_matching_tag = @"not filtered out";
    
    NSString *const disabledNetworkName = @"disabled_network";
    
    HZCreativeType const expectedCreativeType = HZCreativeTypeStatic;
    
    beforeEach(^{
        mockAdapter = [KWMock mockForClass:[HZBaseAdapter class]];
        [mockAdapter stub:@selector(name) andReturn:@"test_adapter"];
        segment = [[HZSegmentationSegment alloc] initWithTags:@[] disabledNetworks:@[disabledNetworkName] placementIDOverrides:@{} frequencyLimitRules:@[] name:@"test segment"];
        ruleMock1 = [KWMock nullMockForClass:[HZSegmentationFrequencyLimitRule class]];
        ruleMock2 = [KWMock nullMockForClass:[HZSegmentationFrequencyLimitRule class]];
        [ruleMock1 stub:@selector(parentAdapter) andReturn:segment];
        [ruleMock2 stub:@selector(parentAdapter) andReturn:segment];
        segment.frequencyLimitRules = @[ruleMock1, ruleMock2];
    });
    
    it(@"Loads its frequency rules correctly", ^{
        const int ptr = 20;//use address of this as fake pointer to db mocks will return
        
        for(HZSegmentationFrequencyLimitRule *ruleMock in segment.frequencyLimitRules) {
            [[ruleMock should] receive:@selector(loadWithDb:) withArguments:theValue((sqlite3 *)&ptr)]; //db won't be used - just use pointer to random var
        }
        
        [segment loadWithDb:(sqlite3 *)&ptr];
    });
    
    
    it(@"Applies to requests with matching tag", ^{
        segment.adTags = @[tag, other_tag];
        BOOL recorded = [segment appliesToRequestWithTag:tag];
        [[theValue(recorded) should] equal:theValue(YES)];
        recorded = [segment appliesToRequestWithTag:other_tag];
        [[theValue(recorded) should] equal:theValue(YES)];
    });
    
    it(@"Applies to all requests when it has no tag filter", ^{
        BOOL recorded = [segment appliesToRequestWithTag:not_matching_tag];
        [[theValue(recorded) should] equal:theValue(YES)];
    });
    
    it(@"Does not apply to requests with mismatching tag", ^{
        segment.adTags = @[tag, other_tag];
        BOOL recorded = [segment appliesToRequestWithTag:not_matching_tag];
        [[theValue(recorded) should] equal:theValue(NO)];
    });
    
    it(@"Does not record an impression with frequencyLimitRules if tag doesn't match", ^{
        segment.adTags = @[tag, other_tag];
        
        for(HZSegmentationFrequencyLimitRule *ruleMock in segment.frequencyLimitRules) {
            [[ruleMock shouldNot] receive:@selector(recordImpressionWithCreativeType:adapter:date:)];
        }
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:not_matching_tag date:[NSDate date]];
        [[theValue(recorded) should] equal:theValue(NO)];
    });
    
    it(@"Records an impression with frequencyLimitRules if tag matches", ^{
        segment.adTags = @[tag, other_tag];
        
        for(HZSegmentationFrequencyLimitRule *ruleMock in segment.frequencyLimitRules) {
            [[ruleMock should] receive:@selector(recordImpressionWithCreativeType:adapter:date:) andReturn:theValue(YES) withCount:1];
        }
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag date:[NSDate date]];
        [[theValue(recorded) should] equal:theValue(YES)];
    });
    
    it(@"Records an impression with frequencyLimitRules if not filtering for tags", ^{
        segment.adTags = @[];
        
        for(HZSegmentationFrequencyLimitRule *ruleMock in segment.frequencyLimitRules) {
            [[ruleMock should] receive:@selector(recordImpressionWithCreativeType:adapter:date:) andReturn:theValue(YES) withCount:1];
        }
        
        BOOL recorded = [segment recordImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag date:[NSDate date]];
        [[theValue(recorded) should] equal:theValue(YES)];
    });
    
    it(@"Does not limit an impression if tag doesn't match", ^{
        segment.adTags = @[tag, other_tag];
        
        for(HZSegmentationFrequencyLimitRule *ruleMock in segment.frequencyLimitRules) {
            [[ruleMock shouldNot] receive:@selector(limitsImpressionWithCreativeType:adapter:)];
        }
        
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Does not limit an impression if all rules say not to", ^{
        segment.adTags = @[tag, other_tag];
        
        for(HZSegmentationFrequencyLimitRule *ruleMock in segment.frequencyLimitRules) {
            [[ruleMock should] receive:@selector(limitsImpressionWithCreativeType:adapter:) andReturn:theValue(NO) withCount:2];
        }
        
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        //again, no tag filter
        segment.adTags = @[];
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag];
        [[theValue(limited) should] equal:theValue(NO)];
    });
    
    it(@"Limits an impression if at least 1 rule says to", ^{
        segment.adTags = @[tag, other_tag];
        
        [[ruleMock1 should] receive:@selector(limitsImpressionWithCreativeType:adapter:) andReturn:theValue(NO) withCount:2];
        [[ruleMock2 should] receive:@selector(limitsImpressionWithCreativeType:adapter:) andReturn:theValue(YES) withCount:2];
        
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        
        //again, no tag filter
        segment.adTags = @[];
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
    });
    
    it(@"Always limits impressions if adapter is disabled unless tag doesn't match filter", ^{
        
        // have them say no to prove them saying yes is not the reason the test succeeds
        for(HZSegmentationFrequencyLimitRule *ruleMock in segment.frequencyLimitRules) {
            [ruleMock stub:@selector(limitsImpressionWithCreativeType:adapter:) andReturn:theValue(NO)];
        }
        
        [mockAdapter stub:@selector(name) andReturn:disabledNetworkName];
        
        segment.adTags = @[tag, other_tag];
        
        BOOL limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(NO)];
        
        
        // again, no tag filter.
        segment.adTags = @[];
        
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:tag];
        [[theValue(limited) should] equal:theValue(YES)];
        limited = [segment limitsImpressionWithCreativeType:expectedCreativeType adapter:mockAdapter tag:not_matching_tag];
        [[theValue(limited) should] equal:theValue(YES)];
    });
    
});

SPEC_END
