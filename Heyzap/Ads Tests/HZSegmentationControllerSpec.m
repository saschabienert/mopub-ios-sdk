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

@property (nonnull, nonatomic) NSSet *segments;

- (NSUInteger) impressionCount;

@end

SPEC_BEGIN(HZSegmentationControllerSpec)
describe(@"HZSegmentationSegment", ^{
    
    __block HZSegmentationController *segmentationController;
    __block NSDictionary * startDictionary;
    __block NSUInteger numberOfSegmentsInStartDictionary;
    
    beforeEach(^{
        segmentationController = [[HZSegmentationController alloc] init];
    });
    
    beforeAll(^{
        startDictionary = [TestJSON mediationStartJSONThatShouldProduceFourSegments];
        numberOfSegmentsInStartDictionary = 4;
    });
    
    it(@"Should start enabled", ^{
        [[theValue(segmentationController.enabled) should] equal:theValue(YES)];
    });
    
    it(@"Should correctly parse the start response from med.heyzap.com", ^{
        [[[segmentationController segments] should] beEmpty];
        [segmentationController setupFromMediationStart:startDictionary completion:nil];
        [[theValue([[segmentationController segments] count]) should] equal:theValue(numberOfSegmentsInStartDictionary)];
    });
    
    it(@"Shouldn't interact with segments or limit impressions when disabled", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZBaseAdapter *adapterMock = [KWMock mockForClass:[HZBaseAdapter class]];
        segmentationController.segments = [NSSet setWithArray:@[segmentMock]];
        
        segmentationController.enabled = NO;
        
        [[segmentMock shouldNot] receive:@selector(limitsImpressionWithCreativeType:auctionType:tag:)];
        BOOL allowed = [segmentationController allowAdapter:adapterMock toShowAdForCreativeType:HZCreativeTypeStatic tag:@"tag"];
        [[theValue(allowed) should] equal:theValue(YES)];
        
        [[segmentMock shouldNot] receive:@selector(recordImpressionWithCreativeType:auctionType:tag:date:)];
        [segmentationController recordImpressionWithCreativeType:HZCreativeTypeStatic tag:@"tag" adapter:adapterMock];
    });
    
    it(@"Should not allow an adapter to show an ad when at least one segment says it shouldn't", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZBaseAdapter *adapterMock = [KWMock mockForClass:[HZBaseAdapter class]];
        NSString *const tag = @"tag";
        HZCreativeType const creativeType = HZCreativeTypeStatic;
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(limitsImpressionWithCreativeType:auctionType:tag:) andReturn:theValue(NO) withCountAtMost:1 arguments:theValue(creativeType), any(), tag]; // since segments is a set (unordered), this mock may not be queried since the segmentation controller can stop asking segments after one does limit the impression
        [[segmentMock2 should] receive:@selector(limitsImpressionWithCreativeType:auctionType:tag:) andReturn:theValue(YES) withCount:1 arguments:theValue(creativeType), any(), tag];
        BOOL allowed = [segmentationController allowAdapter:adapterMock toShowAdForCreativeType:creativeType tag:tag];
        [[theValue(allowed) should] equal:theValue(NO)];
    });
    
    it(@"Should allow an adapter to show an ad when all segments says it should", ^{
        HZSegmentationSegment *segmentMock = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZSegmentationSegment *segmentMock2 = [KWMock mockForClass:[HZSegmentationSegment class]];
        HZBaseAdapter *adapterMock = [KWMock mockForClass:[HZBaseAdapter class]];
        NSString *const tag = @"tag";
        HZCreativeType const creativeType = HZCreativeTypeStatic;
        
        segmentationController.segments = [NSSet setWithArray:@[segmentMock, segmentMock2]];
        
        [[segmentMock should] receive:@selector(limitsImpressionWithCreativeType:auctionType:tag:) andReturn:theValue(NO) withCount:1 arguments:theValue(creativeType), any(), tag];
        [[segmentMock2 should] receive:@selector(limitsImpressionWithCreativeType:auctionType:tag:) andReturn:theValue(NO) withCount:1 arguments:theValue(creativeType), any(), tag];
        BOOL allowed = [segmentationController allowAdapter:adapterMock toShowAdForCreativeType:creativeType tag:tag];
        [[theValue(allowed) should] equal:theValue(YES)];
    });
});

SPEC_END