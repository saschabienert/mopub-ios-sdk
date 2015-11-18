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

@property (nonatomic) BOOL isRefreshingMediate;
@property (nonatomic, strong) dispatch_queue_t cacheWriteQueue;

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
        _cacheWriteQueue = dispatch_queue_create("com.heyzap.sdk.mediation.mediaterequester.cachewrite", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_cacheWriteQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    return self;
}

- (void)start {
    [self loadMediateFromNetwork];
}

- (void)loadMediateFromNetwork {
    // Should be all ad types? none?
    // HZAdFetchRequest requires the main queue; it's getting the status bar orientation and screen size and such.
    // TODO: It seems bad to create an arbitrary HZAdFetchRequest just to get the parameters.
    // Potentially that code can be factored out into something both HZAdFetchRequest and this use?
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithFetchableCreativeType:HZFetchableCreativeTypeStatic
                                                                                    tag:nil
                                                                            auctionType:HZAuctionTypeMixed
                                                                    andAdditionalParams:@{}];
    
    // TODO: cleanup the process of getting mediateParams.
    NSMutableDictionary *const mediateParams = [request.createParams mutableCopy];
    [mediateParams removeObjectForKey:@"creative_type"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[HZMediationAPIClient sharedClient] GET:@"mediate"
                                      parameters:mediateParams
                                         success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
                                             self.isRefreshingMediate = NO;
                                             self.latestMediate = json;
                                             self.latestMediateParams = mediateParams;
                                             [self.delegate requesterUpdatedMediate];
                                             self.consecutiveMediateFailures = 0;
                                             self.mediateRequestDelay = initialMediateDelay;
                                             
                                             // Background priority b/c we shouldn't need to use the cache often.
                                             dispatch_async(self.cacheWriteQueue, ^{
                                                 // TODO: These should be in 1 file so the operation is atomic.
                                                 [self.cachingService cacheRootObject:json filename:[[self class] mediateFilename]];
                                                 [self.cachingService cacheRootObject:mediateParams filename:[[self class] mediateParamsFilename]];
                                                 HZDLog(@"HZMediateRequester: Wrote /mediate to disk.");
                                             });
                                         } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                                             // TODO: Mediation servers should return a certain status code telling the client to fallback to cache for X minutes. This would be much better than e.g. the server-side fallback option, and allows us to reduce load on mediation if necessary.
                                             
                                             HZELog(@"HZMediateRequester: Error updating waterfall (/mediate endpoint). Error = %@",error);
                                             
                                             // Require a failing status code, otherwise things like internet being down will cause a cache fallback.
                                             if (operation.response.statusCode >= 500 && operation.response.statusCode < 600) {
                                                 self.consecutiveMediateFailures += 1;
                                                 HZELog(@"HZMediateRequester: /mediate has returned status code %d, and a 5xx error has occured %u consecutive time(s) so far.", (int)operation.response.statusCode, (unsigned int)self.consecutiveMediateFailures);
                                                 // only uses cache at app startup after 3 failures, otherwise we already have the old one to keep using
                                                 if (self.consecutiveMediateFailures >= 3 && self->_latestMediate == nil) {
                                                     [self restoreFromCache];
                                                 }
                                             }
                                             // TODO: Potentially immediately go to 5 minutes before /mediate based on e.g. status code / header telling us to do so?
                                             
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.mediateRequestDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 self.mediateRequestDelay *= 2;
                                                 [self loadMediateFromNetwork];
                                             });
                                         }];
    });
}

- (void)refreshMediate {
    self.isRefreshingMediate = YES;
    HZDLog(@"HZMediateRequester: refreshing /mediate.");
    [self loadMediateFromNetwork];
}

- (void)restoreFromCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSDictionary *mediatePlist = [self.cachingService rootObjectWithFilename:[[self class] mediateFilename]];
        NSDictionary *mediateParamsPlist = [self.cachingService rootObjectWithFilename:[[self class] mediateParamsFilename]];
        
        if (mediatePlist && mediateParamsPlist) {
            dispatch_async(dispatch_get_main_queue(), ^{
                HZELog(@"HZMediateRequester: /mediate refreshed from cache.");
                self.latestMediate = mediatePlist;
                self.latestMediateParams = mediateParamsPlist;
                [self.delegate requesterUpdatedMediate];
            });
        }
    });
}

- (NSDictionary *) latestMediate {
    if (self.isRefreshingMediate) {
        HZELog(@"HZMediateRequester: The latest mediate response being accessed has already been used to show an ad.");
    }
    return _latestMediate;
}

@end
