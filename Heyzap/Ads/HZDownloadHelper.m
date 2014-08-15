//
//  HZDownloadHelper.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZDownloadHelper.h"
#import "HZAFNetworking.h"
#import "HZLog.h"
#import "HZMetrics.h"

NSString * const HZDownloadHelperSuccessNotification = @"HZDownloadHelperSuccessNotification";

@implementation HZDownloadHelper

+ (HZAFHTTPRequestOperation *) downloadURL: (NSURL *) url toFilePath: (NSString *) filePath forTag:(NSString *)tag andType:(NSString *)type withCompletion:(void (^)(BOOL result))completion {

    __block NSDate *startDownload = [NSDate date];
    
    NSURLRequest *request =  [NSURLRequest requestWithURL:url
                                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                 timeoutInterval:20.0];
    
    HZAFHTTPRequestOperation *operation = [[HZAFHTTPRequestOperation alloc] initWithRequest:request];
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath: filePath append:NO];
    __block BOOL loggedTotal = NO;
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead){
        float decimal = (float)totalBytesRead / (float)totalBytesExpectedToRead;
        int percent = (int) (decimal * 100);
        [HZMetrics sharedInstance].downloadPercentage = percent;
        if (!loggedTotal){
            [[HZMetrics sharedInstance] logMetricsEvent:@"video-size" value:@(totalBytesExpectedToRead) tag:tag type:type];
            loggedTotal = YES;
        }
    }];

    
    [operation setCompletionBlockWithSuccess:^(HZAFHTTPRequestOperation *operation, id responseObject) {
        NSTimeInterval executionTime = [[NSDate date] timeIntervalSinceDate:startDownload];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:HZDownloadHelperSuccessNotification
                                                                object:nil
                                                              userInfo:@{@"info": [NSNumber numberWithDouble: executionTime] , @"path": filePath, @"url": url}];
        });
        
        [HZLog debug: [NSString stringWithFormat: @"(DOWNLOAD) %@ in %f seconds", [url absoluteString], executionTime]];
        
        if (completion) {
            completion(YES);
        }
        

    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO);
        }
    }];
    
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        
    }];
    
    __block HZAFHTTPRequestOperation *bOperation = operation;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        [bOperation cancel];
    }];
    
    [operation start];
    
    return operation;
}

@end
