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

NSString * const HZDownloadHelperSuccessNotification = @"HZDownloadHelperSuccessNotification";

@implementation HZDownloadHelper

+ (HZAFHTTPRequestOperation *) downloadURL: (NSURL *) url toFilePath: (NSString *) filePath withCompletion:(void (^)(BOOL result))completion {

    __block NSDate *startDownload = [NSDate date];
    
    NSMutableURLRequest *request =  [NSURLRequest requestWithURL:url
                                                     cachePolicy:NSURLCacheStorageNotAllowed
                                                 timeoutInterval:20.0];
    
    HZAFHTTPRequestOperation *operation = [[HZAFHTTPRequestOperation alloc] initWithRequest:request];
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath: filePath append:NO];
    
    
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
