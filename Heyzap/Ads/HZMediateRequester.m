//
//  HZMediate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/15/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediateRequester.h"
#import "HZAdFetchRequest.h"
#import "HZMediationAPIClient.h"
#import "HZMediationConstants.h"
#import "HZUtils.h"

// Backoff time for /mediate?

@interface HZMediateRequester()

@property (nonatomic) NSTimeInterval mediateRequestDelay;
@property (nonatomic) NSDictionary *latestMediate;
@property (nonatomic) NSDictionary *latestMediateParams;
@property (nonatomic) BOOL mediateRequestInProgress;

@end

@implementation HZMediateRequester

const NSTimeInterval initialMediateDelay = 5;
const NSTimeInterval maxMediateDelay     = 300;

+ (NSURL *)pathToMediatePlist {
    return [NSURL fileURLWithPath:[HZUtils cacheDirectoryWithFilename:@"mediate.plist"] isDirectory:NO];
}

+ (NSURL *)pathToMediateParamsPlist {
    return [NSURL fileURLWithPath:[HZUtils cacheDirectoryWithFilename:@"mediateParams.plist"] isDirectory:NO];
}

- (void)setMediateRequestDelay:(NSTimeInterval)mediateRequestDelay {
    _mediateRequestDelay = MIN(mediateRequestDelay, maxMediateDelay);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mediateRequestDelay = initialMediateDelay;
    }
    return self;
}

const NSInteger kHZBackOffStatusCode = 420;

- (void)start {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.latestMediate = [NSDictionary dictionaryWithContentsOfURL:[[self class] pathToMediatePlist]];
        self.latestMediateParams = [NSDictionary dictionaryWithContentsOfURL:[[self class] pathToMediateParamsPlist]];
        
        if (self.latestMediate) {
            NSLog(@"Loaded latest /mediate from disk");
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadMediateFromNetwork];
        });
    });
}

- (void)loadMediateFromNetwork {
    HZParameterAssert([NSThread isMainThread]);
    // Should be all ad types? none?
    // HZAdFetchRequest requires the main queue; it's getting the status bar orientation and screen size and such.
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:@[@"all"] // TODO ?
                                                                         adUnit:@"all" // TODO ?
                                                                            tag:nil
                                                                    auctionType:HZAuctionTypeMixed
                                                            andAdditionalParams:@{}];
    
    NSDictionary *const mediateParams = request.createParams;
    
    self.mediateRequestInProgress = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[HZMediationAPIClient sharedClient] GET:@"mediate"
                                      parameters:mediateParams
                                         success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
                                             self.latestMediate = json;
                                             self.latestMediateParams = mediateParams;
                                             self.mediateRequestInProgress = NO;
                                             
                                             // Background priority b/c we shouldn't need to use the cache often.
                                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                                 // TODO: These should be in 1 file so the operation is atomic.
                                                 [json writeToURL:[[self class] pathToMediatePlist] atomically:YES];
                                                 [mediateParams writeToURL:[[self class] pathToMediateParamsPlist] atomically:YES];
                                                 HZDLog(@"Wrote /mediate to disk");
                                             });
                                         } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                                             
                                             // TODO: Potentially immediately go to 5 minutes before /mediate based on e.g. status code / header telling us to do so?
                                             
                                             HZELog(@"Error updating waterfall (/mediate endpoint). Error = %@",error);
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.mediateRequestDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 self.mediateRequestDelay *= 2;
                                                 [self loadMediateFromNetwork];
                                             });
                                         }];
    });
}

- (void)refreshMediate {
    if (!self.mediateRequestInProgress) {
        [self loadMediateFromNetwork];
    }
}

@end
