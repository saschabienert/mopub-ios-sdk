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
#import "HZEnums.h"
#import "HZUtils.h"

NSString * const HZDownloadHelperSuccessNotification = @"HZDownloadHelperSuccessNotification";

@implementation HZDownloadHelper

+ (HZAFHTTPRequestOperation *) downloadURL: (NSURL *) url toFilePath: (NSString *) filePath withCompletion:(void (^)(BOOL result))completion {

    __block NSDate *startDownload = [NSDate date];
    
    NSURLRequest *request =  [NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:20.0];
    
    HZAFHTTPRequestOperation *operation = [[HZAFHTTPRequestOperation alloc] initWithRequest:request];
    
    // Make sure we clear the cache before downloading a new video.
    [operation addDependency:clearCacheOperation];
    
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

static NSOperation *clearCacheOperation;

// Somewhat weird to have this here. There's a weird tie between HZDownloadHelper and HZVideoAdModel where they need to know alot about each other.
+ (void)clearCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clearCacheOperation = [NSBlockOperation blockOperationWithBlock:^{
            [HZUtils createCacheDirectory];
            
            NSFileManager *fm = [NSFileManager defaultManager];
            NSArray *dirContents = [fm contentsOfDirectoryAtPath: [HZUtils cacheDirectoryPath] error:nil];
            NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'imp'"];
            NSArray *onlyImpressionFiles = [dirContents filteredArrayUsingPredicate:fltr];
            
            for (NSString *filePath in onlyImpressionFiles) {
                [[NSFileManager defaultManager] removeItemAtPath: [HZUtils cacheDirectoryWithFilename: filePath] error: nil];
            }
        }];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [clearCacheOperation start];
        });
    });
}

@end
