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
#import "HZCachingService.h"

// Backoff time for /mediate?

@interface HZMediateRequester()

@property (nonatomic) NSTimeInterval mediateRequestDelay;
@property (nonatomic) NSDictionary *latestMediate;
@property (nonatomic) NSDictionary *latestMediateParams;

@property (nonatomic) NSUInteger consecutiveMediateFailures;
@property (nonatomic, readonly) id<HZMediateRequesterDelegate>delegate;
@property (nonatomic, strong) HZCachingService *cachingService;

@end

@implementation HZMediateRequester

const NSTimeInterval initialMediateDelay = 3;
const NSTimeInterval maxMediateDelay     = 300;

+ (NSString *)mediateFilename {
    return @"mediate-v2.plist";
}

+ (NSString *)mediateParamsFilename {
    return @"mediateParams-v2.plist";
}

- (void)setMediateRequestDelay:(NSTimeInterval)mediateRequestDelay {
    _mediateRequestDelay = MIN(mediateRequestDelay, maxMediateDelay);
}

- (instancetype)initWithDelegate:(id<HZMediateRequesterDelegate>)delegate cachingService:(HZCachingService*)cachingService {
    self = [super init];
    if (self) {
        _mediateRequestDelay = initialMediateDelay;
        _delegate = delegate;
        _cachingService = cachingService;
    }
    return self;
}

- (void)start {
    [self loadMediateFromNetwork];
}

- (void)loadMediateFromNetwork {
    // Should be all ad types? none?
    // HZAdFetchRequest requires the main queue; it's getting the status bar orientation and screen size and such.
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:[HZMediationConstants creativeTypesForAdType:HZAdTypeInterstitial] // TODO ?
                                                                         adUnit:@"all" // TODO ?
                                                                            tag:nil
                                                                    auctionType:HZAuctionTypeMixed
                                                            andAdditionalParams:@{}];
    
    // TODO: cleanup the process of getting mediateParams.
    NSMutableDictionary *const mediateParams = [request.createParams mutableCopy];
    [mediateParams removeObjectForKey:@"creative_type"];
    [mediateParams removeObjectForKey:@"ad_unit"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[HZMediationAPIClient sharedClient] GET:@"mediate"
                                      parameters:mediateParams
                                         success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
                                             self.latestMediate = json;
                                             self.latestMediateParams = mediateParams;
                                             [self.delegate requesterUpdatedMediate];
                                             self.consecutiveMediateFailures = 0;
                                             self.mediateRequestDelay = initialMediateDelay;
                                             
                                             // Background priority b/c we shouldn't need to use the cache often.
                                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                                 // TODO: These should be in 1 file so the operation is atomic.
                                                 
                                                 [self.cachingService cacheRootObject:json filename:[[self class] mediateFilename]];
                                                 [self.cachingService cacheRootObject:mediateParams filename:[[self class] mediateParamsFilename]];
                                                 HZDLog(@"Wrote /mediate to disk");
                                             });
                                         } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                                             // TODO: Mediation servers should return a certain status code telling the client to fallback to cache for X minutes. This would be much better than e.g. the server-side fallback option, and allows us to reduce load on mediation if necessary.
                                             
                                             // Require a failing status code, otherwise things like internet being down will cause a cache fallback.
                                             if (operation.response.statusCode >= 500 && operation.response.statusCode < 600) {
                                                 self.consecutiveMediateFailures += 1;
                                                 
                                                 if (self.consecutiveMediateFailures >= 3 && self.latestMediate == nil) {
                                                     [self restoreFromCache];
                                                 }
                                             }
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
    self.latestMediate = nil;
    self.latestMediateParams = nil;
    
    [self loadMediateFromNetwork];
}

- (void)restoreFromCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSDictionary *mediatePlist = [self.cachingService rootObjectWithFilename:[[self class] mediateFilename]];
        NSDictionary *mediateParamsPlist = [self.cachingService rootObjectWithFilename:[[self class] mediateParamsFilename]];
        
        if (mediatePlist && mediateParamsPlist) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.latestMediate = mediatePlist;
                self.latestMediateParams = mediateParamsPlist;
                [self.delegate requesterUpdatedMediate];
            });
        }
    });
}

@end
