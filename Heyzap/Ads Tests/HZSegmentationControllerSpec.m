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
    
    beforeAll(^{
        segmentationController = [[HZSegmentationController alloc] init];
        startDictionary = [TestJSON mediationStartJSONThatShouldProduceFourSegments];
        numberOfSegmentsInStartDictionary = 4;
        
    });
    
    it(@"Should correctly parse the start response from med.heyzap.com", ^{
        [[[segmentationController segments] should] beEmpty];
        [segmentationController setupFromMediationStart:startDictionary completion:nil];
        [[theValue([[segmentationController segments] count]) should] equal:theValue(numberOfSegmentsInStartDictionary)];
    });

});

SPEC_END