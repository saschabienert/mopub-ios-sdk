//
//  HZErrorReportingConfig.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZErrorReportingConfig.h"
#import "HZDictionaryUtils.h"

@implementation HZErrorReportingConfig

NSString * const kHZReportErrorsKey = @"report_errors";
NSString * const kHZReportMetricsKey = @"report_metrics";
NSString * const kHZSecondsBetweenReportsKey = @"seconds_between_error_reports";
NSString * const kHZSecondsToReportAfterFirstError = @"seconds_to_report_after_first_error";

const NSTimeInterval hzTenMinutes = 60 * 10;


- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _reportErrors = [[HZDictionaryUtils objectForKey:kHZReportErrorsKey ofClass:[NSNumber class] default:@YES dict:dictionary] boolValue];
        _reportMetrics = [[HZDictionaryUtils objectForKey:kHZReportMetricsKey ofClass:[NSNumber class] default:@YES dict:dictionary] boolValue];
        _secondsBetweenErrorReports = [[HZDictionaryUtils objectForKey:kHZSecondsBetweenReportsKey ofClass:[NSNumber class] default:@(hzTenMinutes) dict:dictionary] unsignedIntegerValue];
        _secondsToReportAfterFirstError = [[HZDictionaryUtils objectForKey:kHZSecondsToReportAfterFirstError ofClass:[NSNumber class] default:@(30) dict:dictionary] unsignedIntegerValue];
    }
    return self;
}

@end
