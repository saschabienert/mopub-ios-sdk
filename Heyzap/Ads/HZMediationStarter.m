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

@interface HZMediationStarter()

@property (nonatomic) NSTimeInterval retryStartDelay;
@property (nonatomic, weak) id<HZMediationStarting> startingDelegate;
@property (nonatomic) HZMediationStartStatus status;
@end

@implementation HZMediationStarter

const NSTimeInterval initialStartDelay = 10;
const NSTimeInterval maxStartDelay     = 300;

- (instancetype)initWithStartingDelegate:(id<HZMediationStarting>)startingDelegate {
    HZParameterAssert(startingDelegate);
    self = [super init];
    if (self) {
        _retryStartDelay = initialStartDelay;
        _startingDelegate = startingDelegate;
        _status = HZMediationStartStatusNotStarted;
    }
    return self;
}

- (void)setRetryStartDelay:(NSTimeInterval)retryStartDelay {
    _retryStartDelay = MIN(retryStartDelay, maxStartDelay);
}

- (void)setStatus:(HZMediationStartStatus)status {
    // Disallow transitioning from started to failure.
    if (_status == HZMediationStartStatusSuccess) {
        return;
    } else {
        _status = status;
    }
}

- (void)start
{
    // Prevent duplicate start calls.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self startFromDisk];
    });
}

+ (NSURL *)pathToStartInfo {
    return [NSURL fileURLWithPath:[HZUtils cacheDirectoryWithFilename:@"start.plist"] isDirectory:NO];
}

- (void)startFromDisk {
    // Load /start info from disk if present
    // This allows us to initialize ad networks as soon as the game launches
    // This avoids the performance overhead of starting them during gameplay
    // And allows faster fetches.
    NSDictionary *startInfo = [NSDictionary dictionaryWithContentsOfURL:[[self class] pathToStartInfo]];
    if (startInfo) {
        [self giveStartDictionaryToDelegate:startInfo];
    }
    // Ping /start regardless, to refresh our on-disk /start info.
    [self retriableStart];
}

// This method should only be called by `start`.
- (void)retriableStart {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[HZMediationAPIClient sharedClient] GET:@"start" parameters:nil success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
            
            // store JSON to disk
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [json writeToURL:[[self class] pathToStartInfo] atomically:YES];
                HZDLog(@"Wrote start info to disk");
            });
            
            [self giveStartDictionaryToDelegate:json];
            
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            self.status = HZMediationStartStatusFailure;
            HZELog(@"Error! Failed to get networks from Heyzap. Retrying in %g seconds. Error = %@,",self.retryStartDelay, error);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryStartDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.retryStartDelay *= 2;
                [self retriableStart];
            });
        }];
    });
}

- (void)giveStartDictionaryToDelegate:(NSDictionary *)dictionary {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.status = HZMediationStartStatusSuccess;
        [self.startingDelegate startWithDictionary:dictionary];
    });
}

@end
