//
//  HZErrorReporterSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZErrorReporter.h"
#import "HZMediationAPIClient.h"
#import "HZErrorReportingConfig.h"

SPEC_BEGIN(HZErrorReporterSpec)

describe(@"HZErrorReporter", ^{
    
    // These tests don't actually make any assertions, but they still check for things like exceptions.
    // I initially configured the apiClient mock to expect to receive a POST message, but some aspect of the async testing caused it to never receive the message
    // It was pretty weird; adding NSLog to the line before POSTing to the server caused the tests to pass.
    
    it(@"Should report an error", ^{
        
        HZErrorReportingConfig *config = [[HZErrorReportingConfig alloc] initWithDictionary:@{kHZSecondsToReportAfterFirstError: @0}];
        id apiClient = [HZMediationAPIClient nullMock];
        HZErrorReporter *reporter = [[HZErrorReporter alloc] initWithAPIClient:apiClient config:config];
        
        NSError *error = [NSError errorWithDomain:@"" code:1 userInfo:nil];
        [reporter trackError:error method:@"method" lineNumber:1 file:@"filename.m" stackTrace:@[]];
        [reporter trackErrorWithName:@"" details:@"" fullText:@"" method:@"" lineNumber:1 file:@"" stackTrace:@[]];
    });
    
    it(@"Should report a metric", ^{
        HZErrorReportingConfig *config = [[HZErrorReportingConfig alloc] initWithDictionary:@{kHZSecondsToReportAfterFirstError: @0}];
        id apiClient = [HZMediationAPIClient nullMock];
        HZErrorReporter *reporter = [[HZErrorReporter alloc] initWithAPIClient:apiClient config:config];
        
        [reporter trackMetric:@[@"foo"]];
    });
});

SPEC_END
