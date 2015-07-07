//
//  HZMediationLoadManager.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationLoadManager.h"
#import "HZDictionaryUtils.h"
#import "HZMediationLoadData.h"
#import "HZLog.h"
#import "HZBaseAdapter.h"
#import "HZDispatch.h"
#import "HZUtils.h"
#import "HeyzapMediation.h"
#import "HZMediationConstants.h"
#import "HZHeyzapExchangeAdapter.h"

#define CHECK_NOT_NIL1(value) do { \
if (value == nil) { \
return nil; \
} \
} while (0)

@interface HZMediationLoadManager()

@property (nonatomic) NSUInteger maxConcurrency;
@property (nonatomic) NSArray *networkList;

@property (nonatomic, weak) id<HZMediationLoadManagerDelegate> delegate;
@property (nonatomic) BOOL autoFetchEnabled;

// GCD
@property (nonatomic) dispatch_queue_t fetchQueue;

@end

@implementation HZMediationLoadManager

- (instancetype)initWithLoadData:(NSDictionary *)loadData delegate:(id<HZMediationLoadManagerDelegate>)delegate error:(NSError **)error {
    self = [super init];
    if (self) {
        _delegate = delegate;
        
        self.fetchQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_CONCURRENT);
        
        _maxConcurrency = [[HZDictionaryUtils hzObjectForKey:@"max_load" ofClass:[NSNumber class] default:@2 withDict:loadData] unsignedIntegerValue];
        
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:loadData error:error];
        CHECK_NOT_NIL1(networks);
        
        NSMutableArray *const networkList = [NSMutableArray array];
        
        for (NSDictionary *network in networks) {
            NSError *error;
            HZMediationLoadData *const loadData = [[HZMediationLoadData alloc] initWithDictionary:network error:&error];
            if (!loadData) {
                HZELog(@"Error creating HZMediationLoadData: %@",error);
            } else {
                [networkList addObject:loadData];
            }
        }
        
        _networkList = networkList;
    }
    return self;
}

const NSTimeInterval hasAdPollInterval = 3;

- (void)fetchAdType:(HZAdType)adType showOptions:(HZShowOptions *)showOptions optionalForcedNetwork:(Class)forcedNetwork {
    
    NSArray *networksForFetch = hzFilter(self.networkList, ^BOOL(HZMediationLoadData *datum) {
        if (forcedNetwork) {
            return forcedNetwork == datum.adapterClass;
        } else {
            return YES;
        }
    });
    
    NSArray *matching = hzFilter(networksForFetch, ^BOOL(HZMediationLoadData *datum) {
        return hzCreativeTypeSetContainsAdType(datum.creativeTypeSet, adType);
    });
    [self fetchAdType:adType loadData:matching showOptions:showOptions notifyDelegate:YES];
    
    // Should just take all STATIC and VIDEO?
    
    if (adType == HZAdTypeInterstitial) {
        NSArray *videoNetworks = hzFilter(networksForFetch, ^BOOL(HZMediationLoadData *datum) {
            return hzCreativeTypeSetContainsAdType(datum.creativeTypeSet, HZAdTypeVideo);
        });
        [self fetchAdType:HZAdTypeVideo loadData:videoNetworks showOptions:nil notifyDelegate:NO];
        // Also load video, to allow for blending
    }
}

// At fetch time, check if we can show interstitial video
// If yes, include video networks
// If no, don't include video networks
//

// For interstitial, this should ensure that a non-rate-limited network is started.
- (void)fetchAdType:(HZAdType)adType loadData:(NSArray *)loadData showOptions:(HZShowOptions *)showOptions notifyDelegate:(BOOL)notifyDelegate {
    
    dispatch_async(self.fetchQueue, ^{
        
        __block BOOL fetchedAd = NO;
        __block BOOL shouldNotifyDelegate = notifyDelegate;
        
        [loadData enumerateObjectsUsingBlock:^(HZMediationLoadData *datum, NSUInteger idx, BOOL *stop) {
            // we always want the HeyzapExchange to start & fetch so it's bid can be considered in the waterfall on show later, but others shouldn't start unless necessary
            if(fetchedAd && datum.adapterClass != [HZHeyzapExchangeAdapter class]){
                return;
            }
            
            const BOOL setupSuccessful = [self.delegate setupAdapterNamed:datum.networkName];
            
            NSLog(@"Setup successful = %i",setupSuccessful);
            
            if (setupSuccessful) {
                
                __block HZBaseAdapter *adapter;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    adapter = (HZBaseAdapter *)[datum.adapterClass sharedInstance];
                });
                
                dispatch_sync([self.delegate pausableMainQueue], ^{
                    [adapter prefetchForType:adType];
                });
                
                const BOOL anAdapterHasAnAd = hzWaitUntilInterval(hasAdPollInterval, ^BOOL{
                    return [self adaptersFromLoadData:loadData uptoIndexHasAd:idx ofType:adType];
                }, datum.timeout);
                
                if (anAdapterHasAnAd) {
                    fetchedAd = YES;
                    
                    if(datum.adapterClass == [HZHeyzapExchangeAdapter class]){
                        // stop iterating once the exchange succeeds
                        *stop = YES;
                    }
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (shouldNotifyDelegate) {
                            [self.delegate didFetchAdOfType:adType options:showOptions];
                        }
                    });
                    
                    shouldNotifyDelegate = NO; // no longer notify after first notification
                    
                    NSLog(@"An adapter has an ad!");
                    
                }
            }
        }];
        if (!fetchedAd) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (shouldNotifyDelegate) {
                    [self.delegate didFailToFetchAdOfType:adType options:showOptions];
                }
            });
        }
        
    });
}

- (BOOL)adaptersFromLoadData:(NSArray *)loadData uptoIndexHasAd:(NSUInteger)idx ofType:(HZAdType)adType {
    NSLog(@"Adapters = %@ idx = %lu adType = %@",loadData,(unsigned long)idx,NSStringFromAdType(adType));
    for (NSUInteger i = 0; i <= idx; i++) {
        HZMediationLoadData *datum = loadData[i];
        NSLog(@"Instance = %@",[datum.adapterClass sharedInstance]);
        if ([((HZBaseAdapter *)[datum.adapterClass sharedInstance]) hasAdForType:adType]) {
            NSLog(@"Adapter %@ has ad",[datum.adapterClass name]);
            NSLog(@"has ad!");
            return YES;
        } else {
            NSLog(@"no ad");
        }
    }
    return NO;
}

// If
// Need one queue polling network
// Have a timer polling networks, and just have a list of networks to poll?
// How to handle timeouts? Could just do performSelector after delay / dispatch_after

// How to



@end
