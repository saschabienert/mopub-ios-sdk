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
#import "HZMediationPersistentConfig.h"

#import "HZHeyzapExchangeAdapter.h"
#import "HZCrossPromoAdapter.h"

@interface HZMediationLoadManager()

@property (nonatomic) id<HZMediationPersistentConfigReadonly> persistentConfig;
@property (nonatomic) HZSegmentationController *segmentationController;

@property (nonatomic) NSUInteger maxConcurrency;
@property (nonatomic) NSArray<HZBaseAdapter *> *networkList;

@property (nonatomic, weak) id<HZMediationLoadManagerDelegate> delegate;

@property (nonatomic) NSSet<Class> *networksToAlwaysFetch;
@property (nonatomic) NSSet<Class> *networksToKeepLoadingPast;

// GCD
@property (nonatomic) dispatch_queue_t fetchQueue;

@end

@implementation HZMediationLoadManager

- (instancetype)initWithLoadData:(NSDictionary *)loadData delegate:(id<HZMediationLoadManagerDelegate>)delegate persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig segmentationController:(HZSegmentationController *)segmentationController error:(NSError **)error {
    HZParameterAssert(delegate);
    HZParameterAssert(persistentConfig);
    HZParameterAssert(segmentationController);
    self = [super init];
    if (self) {
        _delegate = delegate;
        _persistentConfig = persistentConfig;
        _segmentationController = segmentationController;
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
    
    // currently unused
    self.maxConcurrency = [[HZDictionaryUtils objectForKey:@"max_load" ofClass:[NSNumber class] default:@2 dict:loadData] unsignedIntegerValue];
    
    // these networks should always be fetched:
    // - Exchange should be fetched so it's real-time bid score can be considered in the show waterfall later.
    // - CrossPromo should be fetched since /mediate might put it at the top of the waterfall if their xpromo settings deem a xpromo ad necessary at show time
    NSArray *alwaysFetch = [HZDictionaryUtils objectForKey:@"always_fetch_networks" ofClass:[NSArray class] default:@[[HZCrossPromoAdapter name], [HZHeyzapExchangeAdapter name]] dict:loadData];
    self.networksToAlwaysFetch = [NSSet setWithArray:hzMap(alwaysFetch, ^Class(NSString *networkName) {
        return [HZBaseAdapter adapterClassForName:networkName];
    })];
    
    // We want to guarantee (whenever possible) that there is an ad at the end of a call to fetch that is not from one of the following classes, regardless of any lazy loading going on.
    NSArray *excludeInChecks = [HZDictionaryUtils objectForKey:@"keep_loading_past_networks" ofClass:[NSArray class] default:@[[HZCrossPromoAdapter name]] dict:loadData];
    self.networksToKeepLoadingPast = [NSSet setWithArray:hzMap(excludeInChecks, ^Class(NSString *networkName) {
        return [HZBaseAdapter adapterClassForName:networkName];
    })];
    
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
    
    self.networkList = networkList;
    return YES;
}

- (void)fetchCreativeType:(HZCreativeType)creativeType fetchOptions:(HZFetchOptions *)fetchOptions optionalForcedNetwork:(Class)forcedNetwork notifyDelegate:(BOOL)notifyDelegate {
    HZParameterAssert(fetchOptions);
    const BOOL logFilters = YES;
    
    HZILog(@"LoadManager fetching creativeType: %@ tag: %@ requesting adType: %@ forcedNetwork: %@", NSStringFromCreativeType(creativeType), fetchOptions.tag, NSStringFromAdType(fetchOptions.requestingAdType), forcedNetwork ?: @"(none)");
    
    if (logFilters && forcedNetwork) {
        HZDLog(@"HZMediationLoadManager: only allowing fetch from %@", [forcedNetwork name]);
    }
    
    NSArray *const networksToConsider = hzFilter(self.networkList, ^BOOL(HZMediationLoadData *datum) {
        return forcedNetwork ? forcedNetwork == datum.adapterClass : YES;
    });
    
    // filter out the adapters whose SDKs are not integrated
    NSSet *const availableAdapters = [self.delegate availableAdaptersWithHeyzap:YES];
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
        if ([self.segmentationController allowAdapter:[datum.adapterClass sharedAdapter] toShowAdForCreativeType:creativeType tag:fetchOptions.tag]) {
            return YES;
        } else if(logFilters) {
            HZDLog(@"HZMediationLoadManager: not allowing fetch from %@ because segmentation says it won't allow an ad of creativeType=%@ right now for tag=%@.", [datum.adapterClass name], NSStringFromCreativeType(creativeType), fetchOptions.tag);
        }
        return NO;
    });
    
    HZDLog(@"HZMediationLoadManager: fetching for creativeType=%@ and tag=%@ from networks:\n%@", NSStringFromCreativeType(creativeType), fetchOptions.tag, matching);
    [self fetchCreativeType:creativeType loadData:matching fetchOptions:fetchOptions notifyDelegate:notifyDelegate];
}

// For interstitial, this should ensure that a non-rate-limited network is started.
- (void)fetchCreativeType:(HZCreativeType)creativeType loadData:(NSArray *)loadData fetchOptions:(HZFetchOptions *)fetchOptions notifyDelegate:(BOOL)notifyDelegate {
    HZParameterAssert(loadData);
    HZParameterAssert(fetchOptions);

    // since these properties could update during the fetch process (which is backgrounded), store what the properties are now (on the main thread) and use these const sets instead below
    const NSSet *networksToAlwaysFetch = self.networksToAlwaysFetch;
    const NSSet *networksToKeepLoadingPast = self.networksToKeepLoadingPast;
    
    dispatch_async(self.fetchQueue, ^{
        [networksToAlwaysFetch enumerateObjectsUsingBlock:^(Class adapterClass, BOOL *stop) {
            
            // don't fetch this networkToAlwaysFetch unless it's in the load data also
            HZMediationLoadData *alwaysFetchDatum = hzFirstObjectPassingTest(loadData, ^BOOL(HZMediationLoadData *datum, NSUInteger idx){
                return datum.adapterClass == adapterClass;
            });
            if (!alwaysFetchDatum) {
                return;
            }
            
            // don't fetch if setting up adapter fails
            if (![self.delegate setupAdapterNamed:alwaysFetchDatum.networkName]) {
                return;
            }
            
            HZBaseAdapter *adapter = (HZBaseAdapter *)[alwaysFetchDatum.adapterClass sharedAdapter];
            dispatch_sync([self.delegate pausableMainQueue], ^{
                [adapter prefetchForCreativeType:creativeType];
            });
        }];
        
        
        hzFirstObjectPassingTest(loadData, ^BOOL(HZMediationLoadData *datum, NSUInteger idx) {
         
            const BOOL setupSuccessful = [self.delegate setupAdapterNamed:datum.networkName];
            if (setupSuccessful) {
                
                const HZBaseAdapter *adapter = (HZBaseAdapter *)[datum.adapterClass sharedAdapter];
                dispatch_sync([self.delegate pausableMainQueue], ^{
                    [adapter prefetchForCreativeType:creativeType];
                });
                
                HZDLog(@"Attempting to fetch from %@ for creativeType: %@", [datum.adapterClass humanizedName], NSStringFromCreativeType(creativeType));
                
                const NSTimeInterval pollingInterval = [datum.adapterClass isAvailablePollInterval];
                __block HZBaseAdapter *adapterWithAnAd = nil;
                hzWaitUntilInterval(pollingInterval, ^BOOL{
                    
                    // skip wait time if:
                    //  - the current adapter is one we're going to ignore, and the current (to-be-ignored) adapter already has an ad
                    //      - the requirement that it already has an ad is here so that the ignored network has nonzero time to fetch
                    //        if it's high in the load order (example: the ignored network is the only one in the loadData)
                    //  -- OR --
                    //  - the current adapter has an error for the creativeType
                    const BOOL skipWaitTime = ([networksToKeepLoadingPast containsObject:datum.adapterClass]
                                               && [[datum.adapterClass sharedAdapter] hasAdForCreativeType:creativeType]);
                    if (skipWaitTime) {
                        return true; // stop waiting
                    }
                    
                    const NSError *adapterError = [[datum.adapterClass sharedAdapter] lastFetchErrorForCreativeType:creativeType];
                    if (adapterError){
                        HZELog(@"Not waiting for %@ to fetch because it errored during a fetch for creativeType:%@. Error: %@", [datum.adapterClass humanizedName], NSStringFromCreativeType(creativeType), adapterError);
                        return true; // stop waiting
                    }
                    
                    adapterWithAnAd = [self firstAdapterThatHasAdFromLoadData:loadData inRange:(NSMakeRange(0, idx+1)) ofCreativeType:creativeType tag:fetchOptions.tag excludingClasses:networksToKeepLoadingPast];
                    
                    return (adapterWithAnAd != nil); // stop waiting if we found an adapter
                }, datum.timeout);
                
                if (adapterWithAnAd) {
                    return YES;
                }
            }
            return NO;
        });
        
        // report success with the first adapter in the loadData with an ad w/ no network exclusions, or failure if none have an ad
        //  - the search is re-done here instead of using the adapter retrieved where `*stop = YES` is set above so that the adapter
        //    that we report success with can be one of the networksToExcludeInHasAdChecks - this will report the one highest in the load order
        if (notifyDelegate) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                HZBaseAdapter *finalAdapter = [self firstAdapterThatHasAdFromLoadData:loadData inRange:(NSMakeRange(0, [loadData count])) ofCreativeType:creativeType tag:fetchOptions.tag excludingClasses:[NSSet set]];
                if (finalAdapter) {
                    [self.delegate didFetchAdOfCreativeType:creativeType withAdapter:finalAdapter options:fetchOptions];
                } else {
                    [self.delegate didFailToFetchAdOfCreativeType:creativeType options:fetchOptions];
                }
            });
        }
    });
}

/**
 *  Returns the first adapter that has an allowed ad fetched of the given type, or nil if none in the given range of indices within the passed loadData array have an ad of the given type.
 */
- (HZBaseAdapter *) firstAdapterThatHasAdFromLoadData:(NSArray *)loadData inRange:(NSRange)range ofCreativeType:(HZCreativeType)creativeType tag:(NSString *)tag excludingClasses:(const NSSet *)excludedClasses {
    for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
        HZMediationLoadData *datum = loadData[i];
        HZBaseAdapter *adapter = [datum.adapterClass sharedAdapter];
        BOOL excludeThisAdapter = (excludedClasses != nil && [excludedClasses containsObject:datum.adapterClass]);
        
        if (!excludeThisAdapter
            && [self.delegate isNetworkClassInitialized:[adapter class]]
            && [self.segmentationController adapterHasAllowedAd:adapter forCreativeType:creativeType tag:tag]) {
            return adapter;
        }
    }
    return nil;
}


@end
