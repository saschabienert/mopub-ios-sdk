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
#import "HZMediationPersistentConfig.h"


@interface HZMediationLoadManager()

@property (nonatomic) id<HZMediationPersistentConfigReadonly> persistentConfig;

@property (nonatomic) NSUInteger maxConcurrency;
@property (nonatomic) NSArray *networkList;

@property (nonatomic, weak) id<HZMediationLoadManagerDelegate> delegate;
@property (nonatomic) BOOL autoFetchEnabled;

// GCD
@property (nonatomic) dispatch_queue_t fetchQueue;

@end

@implementation HZMediationLoadManager

- (instancetype)initWithLoadData:(NSDictionary *)loadData delegate:(id<HZMediationLoadManagerDelegate>)delegate persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig error:(NSError **)error {
    HZParameterAssert(delegate);
    HZParameterAssert(persistentConfig);
    self = [super init];
    if (self) {
        _delegate = delegate;
        _persistentConfig = persistentConfig;
        _fetchQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_CONCURRENT);
        if (![self refreshWithLoadData:loadData error:error]) {
            return nil;
        }
    }
    return self;
}

- (BOOL) refreshWithLoadData:(NSDictionary *)loadData error:(NSError **)error {
    
    NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:loadData error:error];
    if(!networks) {
        return NO;
    }
    
    self.maxConcurrency = [[HZDictionaryUtils objectForKey:@"max_load" ofClass:[NSNumber class] default:@2 dict:loadData] unsignedIntegerValue];
        
    NSMutableArray *const networkList = [NSMutableArray array];
    
    for (NSDictionary *network in networks) {
        NSError *err;
        HZMediationLoadData *const loadData = [[HZMediationLoadData alloc] initWithDictionary:network error:&err];
        if (!loadData) {
            HZELog(@"Error creating HZMediationLoadData: %@",err);
        } else {
            [networkList addObject:loadData];
        }
    }
    
    _networkList = networkList;
    return YES;
}

// This method ignores the ad tag in `options.tag` - we fetch regardless of tag. the tag is checked before sending the success callback
- (void)fetchCreativeType:(HZCreativeType)creativeType showOptions:(HZShowOptions *)showOptions optionalForcedNetwork:(Class)forcedNetwork notifyDelegate:(BOOL)notifyDelegate segmentationController:(HZSegmentationController *)segmentationController {
    HZParameterAssert(showOptions);
    const BOOL logFilters = YES;
    
    if (logFilters && forcedNetwork) {
        HZDLog(@"HZMediationLoadManager: only allowing fetch from %@", [forcedNetwork name]);
    }
    
    NSArray *const networksToConsider = hzFilter(self.networkList, ^BOOL(HZMediationLoadData *datum) {
        return forcedNetwork ? forcedNetwork == datum.adapterClass : YES;
    });
    
    // filter out the adapters whose SDKs are not integrated
    NSSet *const availableAdapters = [HeyzapMediation availableAdaptersWithHeyzap:YES];
    NSArray *const availableSDKsForFetch = hzFilter(networksToConsider, ^BOOL(HZMediationLoadData *datum) {
        if ([availableAdapters containsObject:datum.adapterClass]) {
            return YES;
        } else if(logFilters) {
            HZDLog(@"HZMediationLoadManager: not allowing fetch from %@ because SDK is not integrated properly.", [datum.adapterClass name]);
        }
        return NO;
    });
    
    NSArray *const enabledByUser = hzFilter(availableSDKsForFetch, ^BOOL(HZMediationLoadData *datum) {
        if ([self.persistentConfig isNetworkEnabled:[datum.adapterClass name]]) {
            return YES;
        } else if(logFilters) {
            HZDLog(@"HZMediationLoadManager: not allowing fetch from %@ because network is disabled by the user.", [datum.adapterClass name]);
        }
        return NO;
    });
    
    NSArray *const supportsCreativeType = hzFilter(enabledByUser, ^BOOL(HZMediationLoadData *datum) {
        if ([(HZBaseAdapter *)[datum.adapterClass sharedAdapter] supportsCreativeType:creativeType]) {
            return YES;
        } else if(logFilters) {
            HZDLog(@"HZMediationLoadManager: not allowing fetch from %@ because it does not support creativeType=%@", [datum.adapterClass name], NSStringFromCreativeType(creativeType));
        }
        return NO;
    });
    
    NSArray *const hasCredentials = hzFilter(supportsCreativeType, ^BOOL(HZMediationLoadData *datum) {
        if ([(HZBaseAdapter *)[datum.adapterClass sharedAdapter] hasCredentialsForCreativeType:creativeType]) {
            return YES;
        } else if(logFilters) {
            HZDLog(@"HZMediationLoadManager: not allowing fetch from %@ because the adapter does not have credentials for creativeType=%@", [datum.adapterClass name], NSStringFromCreativeType(creativeType));
        }
        return NO;
    });
    
    NSArray *const serverSupportedCreativeType = hzFilter(hasCredentials, ^BOOL(HZMediationLoadData *datum) {
        if (hzCreativeTypeStringSetContainsCreativeType(datum.creativeTypeSet, creativeType)) {
            return YES;
        } else if(logFilters) {
            HZDLog(@"HZMediationLoadManager: not allowing fetch from %@ (\"%@\") because the server did not specify it to show creativeType=%@", [datum.adapterClass name], [[datum.creativeTypeSet allObjects] componentsJoinedByString:@", "], NSStringFromCreativeType(creativeType));
        }
        return NO;
    });
    
    NSArray *const matching = hzFilter(serverSupportedCreativeType, ^BOOL(HZMediationLoadData *datum) {
        if (![segmentationController isAdapterCompletelyDisabledRightNow:[datum.adapterClass sharedAdapter]]) {
            return YES;
        } else if(logFilters) {
            HZDLog(@"HZMediationLoadManager: not allowing fetch from %@ because segmentation says it'll never allow an ad right now.", [datum.adapterClass name]);
        }
        return NO;
    });
    
    HZDLog(@"HZMediationLoadManager: fetching for creativeType=%@ from networks:\n%@", NSStringFromCreativeType(creativeType), matching);
    [self fetchCreativeType:creativeType loadData:matching showOptions:showOptions notifyDelegate:notifyDelegate segmentationController:segmentationController];
}

// At fetch time, check if we can show interstitial video
// If yes, include video networks
// If no, don't include video networks
//

// For interstitial, this should ensure that a non-rate-limited network is started.
- (void)fetchCreativeType:(HZCreativeType)creativeType loadData:(NSArray *)loadData showOptions:(HZShowOptions *)showOptions notifyDelegate:(BOOL)notifyDelegate segmentationController:(HZSegmentationController *)segmentationController {
    HZParameterAssert(loadData);
    HZParameterAssert(showOptions);
    
    dispatch_async(self.fetchQueue, ^{
        
        __block BOOL fetchedAd = NO;
        __block BOOL shouldNotifyDelegate = notifyDelegate;
        __block BOOL hasTriedFetchingHeyzapExchange = NO;
        
        [loadData enumerateObjectsUsingBlock:^(HZMediationLoadData *datum, NSUInteger idx, BOOL *stop) {
            // we always want the HeyzapExchange to start & fetch so it's bid can be considered in the waterfall on show later, but others shouldn't start unless necessary
            if(fetchedAd && datum.adapterClass != [HZHeyzapExchangeAdapter class]){
                return;
            }
            
            if (datum.adapterClass == [HZHeyzapExchangeAdapter class]) {
                hasTriedFetchingHeyzapExchange = YES;
            }
            
            const BOOL setupSuccessful = [self.delegate setupAdapterNamed:datum.networkName];

            if (setupSuccessful) {
                
                __block HZBaseAdapter *adapter;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    adapter = (HZBaseAdapter *)[datum.adapterClass sharedAdapter];
                });
                
                dispatch_sync([self.delegate pausableMainQueue], ^{
                    [adapter prefetchForCreativeType:creativeType];
                });
                
                NSTimeInterval pollingInterval = [datum.adapterClass isAvailablePollInterval];
                __block HZBaseAdapter *adapterWithAnAd = nil;
                const BOOL anAdapterHasAnAd = hzWaitUntilInterval(pollingInterval, ^BOOL{
                    adapterWithAnAd = [self adapterFromLoadData:loadData uptoIndexThatHasAd:idx ofCreativeType:creativeType tag:showOptions.tag segmentationController:segmentationController];
                    return (adapterWithAnAd != nil);
                }, datum.timeout);
                
                if (anAdapterHasAnAd) {
                    if (hasTriedFetchingHeyzapExchange){
                        // stop iterating once the exchange has had a chance to fetch & there is an ad from any network available
                        *stop = YES;
                    }
                    
                    fetchedAd = YES;
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (shouldNotifyDelegate) {
                            [self.delegate didFetchAdOfCreativeType:creativeType withAdapter:adapterWithAnAd options:showOptions];
                        }
                    });
                    
                    shouldNotifyDelegate = NO; // no longer notify after first notification
                }
            }
        }];
        if (!fetchedAd) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (shouldNotifyDelegate) {
                    [self.delegate didFailToFetchAdOfCreativeType:creativeType options:showOptions];
                }
            });
        }
        
    });
}

// Returns the first adapter, from index [0,idx] that has an ad of the given type, or nil if none in that range have an ad of the given type.
- (HZBaseAdapter *)adapterFromLoadData:(NSArray *)loadData uptoIndexThatHasAd:(NSUInteger)idx ofCreativeType:(HZCreativeType)creativeType tag:(NSString *)tag segmentationController:(HZSegmentationController *)segmentationController {
    for (NSUInteger i = 0; i <= idx; i++) {
        HZMediationLoadData *datum = loadData[i];
        HZBaseAdapter *adapter = ((HZBaseAdapter *)[datum.adapterClass sharedAdapter]);
        if ([[HeyzapMediation sharedInstance] isNetworkClassInitialized:[adapter class]] && [segmentationController adapterHasAllowedAd:adapter forCreativeType:creativeType tag:tag]) {
            return adapter;
        }
    }
    return nil;
}

// If
// Need one queue polling network
// Have a timer polling networks, and just have a list of networks to poll?
// How to handle timeouts? Could just do performSelector after delay / dispatch_after

// How to



@end
