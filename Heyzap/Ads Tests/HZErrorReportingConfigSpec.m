//
//  HZErrorReportingConfigSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/9/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZErrorReportingConfig.h"


SPEC_BEGIN(HZErrorReportingConfigSpec)

describe(@"HZErrorReportingConfig", ^{
    it(@"Defaults to reporting errors", ^{
        HZErrorReportingConfig *config = [[HZErrorReportingConfig alloc] initWithDictionary:@{}];
        [[theValue(config.shouldReportErrors) should] beTrue];
        [[theValue(config.shouldReportMetrics) should] beTrue];
        
        [[theValue(config.secondsBetweenErrorReports) should] beGreaterThan:theValue(0)];
        [[theValue(config.secondsToReportAfterFirstError) should] beGreaterThan:theValue(0)];
    });
    it(@"Picks up changed values from the dictionary", ^{
        NSDictionary *dict = @{
                               kHZReportErrorsKey: @NO,
                               kHZReportMetricsKey: @NO,
                               kHZSecondsBetweenReportsKey: @101,
                               kHZSecondsToReportAfterFirstError: @102,
                               };
        HZErrorReportingConfig *config = [[HZErrorReportingConfig alloc] initWithDictionary:dict];
        [[theValue(config.shouldReportErrors) should] beFalse];
        [[theValue(config.shouldReportMetrics) should] beFalse];
        
        [[theValue(config.secondsBetweenErrorReports) should] equal:@101];
        [[theValue(config.secondsToReportAfterFirstError) should] equal:@102];
    });
});

SPEC_END
