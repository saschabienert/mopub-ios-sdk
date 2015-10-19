//
//  HZErrorReporter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZErrorReporter.h"
#import "HZMediationAPIClient.h"
#import "HZErrorReportingConfig.h"
#import "HZLog.h"
#import "HZDevice.h"

@interface HZErrorReporter()

// Dependencies
@property (nonatomic, strong) HZErrorReportingConfig *config;
@property (nonatomic, strong) HZAFHTTPRequestOperationManager *apiClient;
@property (nonatomic, strong) dispatch_queue_t errorReportingQueue;

// State
@property (nonatomic) NSMutableArray *errors;
@property (nonatomic) NSMutableArray *metrics;
@property (nonatomic) NSDate *lastSendDate;

@end

@implementation HZErrorReporter

NSString * const kHZMetricGroupExchange = @"exchange";

// nil arguments should never be passed to this class, but we don't want to crash just to report errors.
#define ERROR_REPORTER_CHECK_NOT_NIL(value) do { \
if (value == nil) { \
HZELog(@"[HZErrorReporter] The parameter %s was nil. This issue won't affect your app, but prevents Heyzap from reporting internal errors to itself. Please report this to support@heyzap.com",#value); \
HZELog(@"Stacktrace = %@",[NSThread callStackSymbols]); \
return; \
} \
} while (0)

#pragma mark - Errors

- (instancetype)initWithAPIClient:(HZAFHTTPRequestOperationManager *)apiClient config:(HZErrorReportingConfig *)config {
    HZParameterAssert(apiClient);
    HZParameterAssert(config);
    
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _config = config;
        
        if (hziOS8Plus()) {
            const dispatch_queue_attr_t lowPrioritySerial = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
            _errorReportingQueue = dispatch_queue_create("com.heyzap.sdk.mediation.error_reporting", lowPrioritySerial);
        } else {
            _errorReportingQueue = dispatch_queue_create("com.heyzap.sdk.mediation.error_reporting", DISPATCH_QUEUE_SERIAL);
            dispatch_set_target_queue(_errorReportingQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
        }
        
        _errors  = [NSMutableArray array];
        _metrics = [NSMutableArray array];
        _lastSendDate = [NSDate distantPast];
    }
    return self;
}

- (void)updateConfig:(HZErrorReportingConfig *)config {
    dispatch_async(self.errorReportingQueue, ^{
        self.config = config;
    });
}

- (void)trackErrorWithName:(NSString *)name details:(NSString *)details fullText:(NSString *)fullText method:(NSString *)method lineNumber:(int)lineNumber file:(NSString *)file stackTrace:(NSArray *)stackTrace {
    dispatch_async(self.errorReportingQueue, ^{
        if (!self.config.shouldReportErrors) {
            return;
        }
        
        ERROR_REPORTER_CHECK_NOT_NIL(name);
        ERROR_REPORTER_CHECK_NOT_NIL(details);
        ERROR_REPORTER_CHECK_NOT_NIL(fullText);
        ERROR_REPORTER_CHECK_NOT_NIL(method);
        ERROR_REPORTER_CHECK_NOT_NIL(file);
        ERROR_REPORTER_CHECK_NOT_NIL(stackTrace);
        
        
        [self storeError:@{
                           @"line":@(lineNumber),
                           @"file": file,
                           @"method": method,
                           @"errorName": name,
                           @"errorDetails": details,
                           @"fullText": fullText,
                           @"stackTrace": stackTrace,
                           @"timestamp": @([[NSDate date] timeIntervalSince1970]),
                           }];
    });
}

- (void)trackError:(NSError *)error method:(NSString *)method lineNumber:(int)lineNumber file:(NSString *)file stackTrace:(NSArray *)stackTrace {
    dispatch_async(self.errorReportingQueue, ^{
        if (!self.config.shouldReportErrors) {
            return;
        }
        
        [self trackErrorWithName:(error.localizedDescription ?: @"Unknown error")
                         details:@""
                        fullText:[error description]
                          method:method
                      lineNumber:lineNumber
                            file:file
                      stackTrace:stackTrace];
    });
}

- (void)storeError:(NSDictionary *)error {
    [self.errors addObject:error];
    [self maybeSendData];
}

#pragma mark - Metrics

- (void)trackMetric:(NSArray *)metricPieces {
    dispatch_async(self.errorReportingQueue, ^{
        [self trackMetric:metricPieces count:1];
    });
}
- (void)trackMetric:(NSArray *)metricPieces count:(NSUInteger)count {
    dispatch_async(self.errorReportingQueue, ^{
        if (!self.config.shouldReportMetrics) {
            return;
        }
        
        ERROR_REPORTER_CHECK_NOT_NIL(metricPieces);
        
        NSString *metricName = [metricPieces componentsJoinedByString:@"."];
        
        [self storeMetric:@{@"name":metricName,
                            @"count":@(count),
                            }];
    });
}

- (void)storeMetric:(NSDictionary *)metric {
    [self.metrics addObject:metric];
    [self maybeSendData];
}

#pragma mark - Sending Data

- (void)maybeSendData {
    if ([[NSDate date] timeIntervalSinceDate:self.lastSendDate] > self.config.secondsBetweenErrorReports) {
        // Send data N seconds later to allow multiple errors/metrics to roll in
        self.lastSendDate = [NSDate date];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.secondsToReportAfterFirstError * NSEC_PER_SEC)), self.errorReportingQueue, ^{
            [self sendData];
        });
    } else {
        __weak __typeof(&*self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.secondsBetweenErrorReports * NSEC_PER_SEC)), self.errorReportingQueue, ^{
            [weakSelf maybeSendData];
        });
    }
}

- (void)sendData {
    NSArray *const errorsToSend  = [self.errors copy];
    NSArray *const metricsToSend = [self.metrics copy];
    
    NSDictionary *const params = @{
                                   @"errors": errorsToSend,
                                   @"metrics": metricsToSend,
                                   };
    
    [self.errors removeAllObjects];
    [self.metrics removeAllObjects];
    
    [self.apiClient POST:@"errors/log" parameters:params success:^(HZAFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        HZELog(@"Error reporting errors to Heyzap's server: %@",error);
    }];
}

@end
