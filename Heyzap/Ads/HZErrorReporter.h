//
//  HZErrorReporter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZAFHTTPRequestOperationManager;
@class HZErrorReportingConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 *  This object tracks errors and error metrics and periodically sends them to mediation-service, where they're sent to Kibana or Graphite, respectively.
 *
 *  All methods on this class are safe to call from any thread.
 */
@interface HZErrorReporter : NSObject

extern NSString * const kHZMetricGroupExchange;

- (void)updateConfig:(HZErrorReportingConfig *)config;

#pragma mark - Initialization

- (instancetype)initWithAPIClient:(HZAFHTTPRequestOperationManager *)apiClient config:(HZErrorReportingConfig *)config;

#pragma mark - Tracking Errors

- (void)trackErrorWithName:(NSString *)name details:(NSString *)details fullText:(NSString *)fullText method:(NSString *)method lineNumber:(int)lineNumber file:(NSString *)file stackTrace:(NSArray *)stackTrace;

- (void)trackError:(NSError *)error method:(NSString *)method lineNumber:(int)lineNumber file:(NSString *)file stackTrace:(NSArray *)stackTrace;

#pragma mark - Tracking Metrics

- (void)trackMetric:(NSArray *)metricPieces;
- (void)trackMetric:(NSArray *)metricPieces count:(NSUInteger)count;

NS_ASSUME_NONNULL_END

@end
