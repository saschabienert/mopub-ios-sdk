//
//  HZMediationStarter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 5/5/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationStarter.h"
#import "HZMediationAPIClient.h"
#import "HZUtils.h"
#import "HZLog.h"
#import "HZDictionaryUtils.h"
#import "HZCachingService.h"

@interface HZMediationStarter()

@property (nonatomic) NSTimeInterval retryStartDelay;
@property (nonatomic, weak) id<HZMediationStarting> startingDelegate;
@property (nonatomic) HZCachingService *cachingService;
@end

@implementation HZMediationStarter

const NSTimeInterval initialStartDelay = 10;
const NSTimeInterval maxStartDelay     = 300;

- (instancetype)initWithStartingDelegate:(id<HZMediationStarting>)startingDelegate cachingService:(HZCachingService *)cachingService {
    HZParameterAssert(startingDelegate);
    HZParameterAssert(cachingService);
    self = [super init];
    if (self) {
        _retryStartDelay = initialStartDelay;
        _startingDelegate = startingDelegate;
        _cachingService = cachingService;
    }
    return self;
}

- (void)setRetryStartDelay:(NSTimeInterval)retryStartDelay {
    _retryStartDelay = MIN(retryStartDelay, maxStartDelay);
}

- (void)start
{
    [self startFromDisk];
}

+ (NSString *)startFilename {
    return @"start-v2.plist";
}

- (void)startFromDisk {
    // Load /start info from disk if present
    // This allows us to initialize ad networks as soon as the game launches
    // This avoids the performance overhead of starting them during gameplay
    // And allows faster fetches.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSDictionary *startInfo = [self.cachingService rootObjectWithFilename:[[self class] startFilename]];
        
        if (startInfo) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self giveStartDictionaryToDelegate:startInfo fromCache:YES];
            });
        }
        // Ping /start regardless, to refresh our on-disk /start info.
        [self retriableStart];
    });
}

// This method should only be called by `start`.
- (void)retriableStart {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[HZMediationAPIClient sharedClient] GET:@"start" parameters:nil success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
            
            [self.startingDelegate receivedStartHeaders:[operation.response allHeaderFields]];
            
            // store JSON to disk
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [self.cachingService cacheRootObject:json filename:[[self class] startFilename]];
                HZDLog(@"Wrote start info to disk");
            });
            
            [self giveStartDictionaryToDelegate:json fromCache:NO];
            
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            HZELog(@"Error! Failed to get networks from Heyzap. Retrying in %g seconds. Error = %@,",self.retryStartDelay, error);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryStartDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.retryStartDelay *= 2;
                [self retriableStart];
            });
        }];
    });
}

- (void)giveStartDictionaryToDelegate:(NSDictionary *)dictionary fromCache:(BOOL)fromCache {
    [self.startingDelegate startWithDictionary:dictionary fromCache:fromCache];
}

@end
