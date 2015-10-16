//
//  HZErrorReportingConfig.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HZErrorReportingConfig : NSObject

extern NSString * const kHZReportErrorsKey;
extern NSString * const kHZReportMetricsKey;
extern NSString * const kHZSecondsBetweenReportsKey;
extern NSString * const kHZSecondsToReportAfterFirstError;

@property (nonatomic, readonly, getter=shouldReportErrors)  BOOL reportErrors;
@property (nonatomic, readonly, getter=shouldReportMetrics) BOOL reportMetrics;
@property (nonatomic, readonly) NSUInteger secondsBetweenErrorReports;
@property (nonatomic, readonly) NSUInteger secondsToReportAfterFirstError;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END