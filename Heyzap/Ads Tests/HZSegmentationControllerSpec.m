//
//  HZSegmentationControllerSpec.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/21/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZSegmentationSegment.h"
#import "HZImpressionHistory.h"

@interface HZSegmentationController (Testing)

@property (nonnull, nonatomic) NSSet<HZSegmentationSegment *> *segments;

@end

SPEC_BEGIN(HZSegmentationControllerSpec)
describe(@"HZSegmentationSegment", ^{
    
    __block HZSegmentationController *segmentationController;
    __block NSDictionary * startDictionary;
    __block NSUInteger numberOfSegmentsInStartDictionary;
    __block HZBaseAdapter *adapterMock;
    
    HZCreativeType const expectedCreativeType = HZCreativeTypeStatic;
    NSString *const tag = @"limited tag";
    
    beforeEach(^{
        segmentationController = [[HZSegmentationController alloc] init];
        adapterMock = [KWMock mockForClass:[HZBaseAdapter class]];
        [adapterMock stub:@selector(name) andReturn:@"heyzap"];
    });
    
    beforeAll(^{
        startDictionary = [TestJSON mediationStartJSONThatShouldProduceSixSegments];
        numberOfSegmentsInStartDictionary = 6;
    });
    
    it(@"Should start enabled", ^{
        [[theValue(segmentationController.enabled) should] equal:theValue(YES)];
    });
    
    it(@"Should correctly parse the start response from med.heyzap.com", ^{
        __block BOOL blockSuccess = NO;
        void (^completionBlock)(BOOL) = ^(BOOL successful) {
            blockSuccess = successful;
        };
        HZImpressionHistory *impressionHistoryMock = [KWMock nullMockForClass:[HZImpressionHistory class]];
        const int ptr = 20;//use address of this as fake pointer to db mocks will return
        
        [[[segmentationController segments] should] beEmpty];
        [[HZImpressionHistory should] receive:@selector(sharedInstance) andReturn:impressionHistoryMock withCountAtLeast:1];
        [[impressionHistoryMock should] receive:@selector(safeImpressionTableDatabaseConnection) andReturn:theValue((sqlite3 *)&ptr)]; //db won't be used - just use pointer to random var
        
        [segmentationController setupFromMediationStart:startDictionary completion:completionBlock];
        [[theValue([[segmentationController segments] count]) should] equal:theValue(numberOfSegmentsInStartDictionary)];
        [[expectFutureValue(theValue(blockSuccess)) hzShouldEventuallyAfterDelay] equal:theValue(YES)];
    });
    
    it(@"Should call failure callback if db connection fails & is null", ^{
        __block BOOL blockSuccess = YES;
        void (^completionBlock)(BOOL) = ^(BOOL successful) {
            blockSuccess = successful;
        };
        HZImpressionHistory *impressionHistoryMock = [KWMock nullMockForClass:[HZImpressionHistory class]];
        
        [[[segmentationController segments] should] beEmpty];
        [[HZImpressionHistory should] receive:@selector(sharedInstance) andReturn:impressionHistoryMock];
        [[impressionHistoryMock should] receive:@selector(safeImpressionTableDatabaseConnection) andReturn:theValue((sqlite3 *)0)]; // simulate db failure
        
        [segmentationController setupFromMediationStart:startDictionary completion:completionBlock];
        [[expectFutureValue(theValue(blockSuccess)) hzShouldEventuallyAfterDelay] equal:theValue(NO)];
    });
    
    it(@"Shouldn't interact with segments, limit impressions, or record impressions when disabled", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZImpressionHistory *impressionHistoryMock = [KWMock mockForClass:[HZImpressionHistory class]];
        segmentationController.segments = [NSSet setWithArray:@[segmentMock]];
        
        segmentationController.enabled = NO;
        
        [[segmentMock shouldNot] receive:@selector(limitsImpressionWithCreativeType:adapter:tag:)];
        
        HZMediationAdAvailabilityDataProvider *metadata = [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:expectedCreativeType tag:@"tag"];
        BOOL allowed = [segmentationController allowAdapter:adapterMock toShowAdWithMetadata:metadata];
        [[theValue(allowed) should] equal:theValue(YES)];
        
        [[segmentMock shouldNot] receive:@selector(recordImpressionWithCreativeType:adapter:tag:date:)];
        [[impressionHistoryMock shouldNot] receive:@selector(recordImpressionWithCreativeType:tag:auctionType:date:)];
        [segmentationController recordImpressionWithCreativeType:expectedCreativeType tag:@"tag" adapter:adapterMock];
    });
    
    it(@"Should report impression to all segments & impression history when enabled", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZImpressionHistory *impressionHistoryMock = [KWMock mockForClass:[HZImpressionHistory class]];
        
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(recordImpressionWithCreativeType:adapter:tag:date:) withCount:1 arguments:theValue(expectedCreativeType), any(), tag, any()];
        [[segmentMock2 should] receive:@selector(recordImpressionWithCreativeType:adapter:tag:date:) withCount:1 arguments:theValue(expectedCreativeType), any(), tag, any()];
        
        [[HZImpressionHistory should] receive:@selector(sharedInstance) andReturn:impressionHistoryMock];
        [[impressionHistoryMock should] receive:@selector(recordImpressionWithCreativeType:tag:auctionType:date:)];
        
        [segmentationController recordImpressionWithCreativeType:expectedCreativeType tag:tag adapter:adapterMock];
    });
    
    it(@"Should not allow an adapter to show an ad when at least one segment says it shouldn't", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(limitsImpressionWithCreativeType:adapter:tag:) andReturn:theValue(NO) withCountAtMost:1 arguments:theValue(expectedCreativeType), adapterMock, tag]; // since segments is a set (unordered), this mock may not be queried since the segmentation controller can stop asking segments after one does limit the impression
        [[segmentMock2 should] receive:@selector(limitsImpressionWithCreativeType:adapter:tag:) andReturn:theValue(YES) withCount:1 arguments:theValue(expectedCreativeType), adapterMock, tag];
        
        HZMediationAdAvailabilityDataProvider *metadata = [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:expectedCreativeType tag:tag];
        BOOL allowed = [segmentationController allowAdapter:adapterMock toShowAdWithMetadata:metadata];
        [[theValue(allowed) should] equal:theValue(NO)];
    });
    
    it(@"Should allow an adapter to show an ad when all segments says it should", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(limitsImpressionWithCreativeType:adapter:tag:) andReturn:theValue(NO) withCount:1 arguments:theValue(expectedCreativeType), adapterMock, tag];
        [[segmentMock2 should] receive:@selector(limitsImpressionWithCreativeType:adapter:tag:) andReturn:theValue(NO) withCount:1 arguments:theValue(expectedCreativeType), adapterMock, tag];
        
        HZMediationAdAvailabilityDataProvider *metadata = [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:expectedCreativeType tag:tag];
        BOOL allowed = [segmentationController allowAdapter:adapterMock toShowAdWithMetadata:metadata];
        [[theValue(allowed) should] equal:theValue(YES)];
    });
    
    it(@"Should return a matching placement ID override when at least one segment has one with a matching network name", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        
        NSString *networkString = @"network";
        NSString *overrideString = @"override";
        HZCreativeType creativeType = HZCreativeTypeVideo;
        NSDictionary *overrideDict = @{networkString:@{NSStringFromCreativeType(creativeType): overrideString}};
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(NO) withCount:1 arguments:tag];
        [[segmentMock2 should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(YES) withCount:1 arguments:tag];
        
        [[segmentMock2 should] receive:@selector(placementIDOverrides) andReturn:overrideDict];
        [[adapterMock should] receive:@selector(name) andReturn:networkString];
        
        NSString *returnedOverride = [segmentationController placementIDOverrideForAdapter:adapterMock tag:tag creativeType:creativeType];
        [[returnedOverride should] equal:overrideString];
    });
    
    it(@"Should return a nil placement ID override when at least one segment has an override, but with no matching network name", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        
        NSString *networkString = @"network";
        NSString *wrongNetworkString = @"other_network";
        NSString *overrideString = @"override";
        HZCreativeType creativeType = HZCreativeTypeVideo;
        NSDictionary *overrideDict = @{networkString:@{NSStringFromCreativeType(creativeType): overrideString}};
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(NO) withCount:1 arguments:tag];
        [[segmentMock2 should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(YES) withCount:1 arguments:tag];
        
        [[segmentMock2 should] receive:@selector(placementIDOverrides) andReturn:overrideDict];
        [[adapterMock should] receive:@selector(name) andReturn:wrongNetworkString];
        
        NSString *returnedOverride = [segmentationController placementIDOverrideForAdapter:adapterMock tag:tag creativeType:creativeType];
        [[returnedOverride should] beNil];
    });
    
    it(@"Should return one of the placement ID overrides when more than one segment has an override with a matching network name", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        
        NSString *networkString = @"network";
        NSString *overrideString = @"override1";
        NSString *overrideString2 = @"override2";
        HZCreativeType creativeType = HZCreativeTypeVideo;
        NSDictionary *overrideDict = @{networkString:@{NSStringFromCreativeType(creativeType): overrideString}};
        NSDictionary *overrideDict2 = @{networkString:@{NSStringFromCreativeType(creativeType): overrideString2}};
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(YES) withCount:1 arguments:tag];
        [[segmentMock2 should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(YES) withCount:1 arguments:tag];
        
        [[segmentMock should] receive:@selector(placementIDOverrides) andReturn:overrideDict];
        [[segmentMock2 should] receive:@selector(placementIDOverrides) andReturn:overrideDict2];
        [[adapterMock should] receive:@selector(name) andReturn:networkString withCountAtLeast:1];
        
        NSString *returnedOverride = [segmentationController placementIDOverrideForAdapter:adapterMock tag:tag creativeType:creativeType];
        [[returnedOverride should] matchPattern:@"override[12]"];
    });
    
    it(@"Should return a nil placement ID override when no segments have an override", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(NO) withCount:1 arguments:tag];
        [[segmentMock2 should] receive:@selector(appliesToRequestWithTag:) andReturn:theValue(NO) withCount:1 arguments:tag];
        
        NSString *returnedOverride = [segmentationController placementIDOverrideForAdapter:adapterMock tag:tag creativeType:HZCreativeTypeVideo];
        [[returnedOverride should] beNil];
    });
});

SPEC_END