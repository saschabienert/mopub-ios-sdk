//
//  HeyzapMediation.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HeyzapMediation.h"
#import "HZBaseAdapter.h"

// Proxies
#import "HZChartboostAdapter.h"
#import "HZHeyzapAdapter.h"
#import "HZAdColonyAdapter.h"
#import "HZVungleAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZVGVunglePub.h"
#import "MediationAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZMediationConstants.h"
#import "HZAdFetchRequest.h"
#import "HeyzapAds.h"

// Util
#import "HZDispatch.h"
#import "DelegateProxy.h"

// Session
#import "HZMediationSessionKey.h"
#import "HZMediationSession.h"

#define HZVideoAdUnit @"video"
#define HZVideoAdCreativeTypes @[@"video", @"interstitial_video"]

#define HZInterstitialAdCreativeTypes @[@"interstitial", @"full_screen_interstitial", @"video", @"interstitial_video"]
#define HZInterstitialAdCreativeTypesNoVideo @[@"interstitial", @"full_screen_interstitial"]
#define HZInterstitialAdUnit @"interstitial"
#define HZIncentivizedAdCreativeTypes @[@"video", @"interstitial_video"]

@interface HeyzapMediation() <HZMediationAdapterDelegate>

@property (nonatomic, strong) NSMutableSet *setupMediators; // Make this an NSSet when we get data from the server

HZAdType hzAdTypeFromString(NSString *adUnit);
NSString * NSStringFromAdType(HZAdType type);

@property (nonatomic, strong) id <HZAdsDelegate> adsDelegate;
@property (nonatomic, strong) id <HZIncentivizedAdDelegate> incentivizedDelegate;

@property (nonatomic, strong) NSMutableDictionary *sessionDictionary;

@end

@implementation HeyzapMediation

#pragma mark -

NSString * const kHZUnknownMediatiorException = @"UnknownMediator";

+ (instancetype)sharedInstance
{
    static HeyzapMediation *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[HeyzapMediation alloc] init];
        mediator.setupMediators = [[NSMutableSet alloc] init];
        mediator.adsDelegate = [[DelegateProxy alloc] init];
        mediator.incentivizedDelegate = [[DelegateProxy alloc] init];
        mediator.sessionDictionary = [NSMutableDictionary dictionary];
    });
    
    return mediator;
}

#pragma mark - Setup

- (void)start
{
    [[MediationAPIClient sharedClient] get:@"start" withParams:nil success:^(NSDictionary *json) {
        
        NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:json];
        [NSOrderedSet orderedSetWithArray:networks];
        if (networks) {
            [self setupMediators:networks];
        } else {
            NSLog(@"Error! Failed to get networks from Heyzap; mediation won't be possible. `networks` was invalid");
        }
    } failure:^(NSError *error) {
        NSLog(@"Error! Failed to get networks from Heyzap. Mediation won't be possible. Error = %@,",error);
    }];
}

- (void)setupMediators:(NSArray *)mediatorJSON
{
    NSMutableSet *setupMediators = [NSMutableSet set];
    for (NSDictionary *mediator in mediatorJSON) {
        NSString *mediatorName = mediator[kHZAdapterKey];
        Class mediatorClass = [HZBaseAdapter adapterClassForName:mediatorName];
        NSDictionary *mediatorInfo = mediator[kHZDataKey];
        if (mediatorClass && mediatorInfo && [mediatorClass isSDKAvailable]) {
            NSError *credentialError = [mediatorClass enableWithCredentials:mediatorInfo];
            if (!credentialError) {
                HZBaseAdapter *adapter = [mediatorClass sharedInstance];
                adapter.delegate = self;
                [setupMediators addObject:adapter];
            } else {
                NSLog(@"Error setting up 3rd-party SDK. Error = %@",credentialError);
            }
        } else {
            NSLog(@"Mediator unavailable");
        }
    }
    self.setupMediators = setupMediators;
    NSLog(@"Setup mediators = %@",setupMediators);
    
    [self mediateForAdType:HZAdTypeInterstitial
                       tag:nil
           showImmediately:NO
              fetchTimeout:10];
}


#pragma mark - Ads


// Potentially I should start up a timer here to try again if we aren't setup yet.
// Downside to that is that we could show an ad like 10s after they asked for it.

- (void)showAdForAdUnitType:(HZAdType)adType tag:(NSString *)tag
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
    
    [self mediateForAdType:adType
                       tag:tag
           showImmediately:YES
              fetchTimeout:2];
}

NSString * NSStringFromAdType(HZAdType type)
{
    if (type & HZAdTypeInterstitial) {
        return @"interstitial";
    } else if (type & HZAdTypeVideo) {
        return @"video";
    } else {
        return @"incentivized";
    }
}

+ (NSArray *)creativeTypesForAdType:(HZAdType)type
{
    switch (type) {
        case HZAdTypeIncentivized: {
            return HZIncentivizedAdCreativeTypes;
            break;
        }
        case HZAdTypeInterstitial: {
            return HZInterstitialAdCreativeTypes;
            break;
        }
        case HZAdTypeVideo: {
            return HZVideoAdCreativeTypes;
            break;
        }
    }
}

- (void)mediateForAdType:(HZAdType)adType tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout
{
    // Need to check for existing session here to prevent double requests.
    if (tag == nil) {
        tag = [HeyzapAds defaultTagName];
    }
    NSString *adUnit = NSStringFromAdType(adType);
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:[[self class] creativeTypesForAdType:adType]
                                                                         adUnit:adUnit
                                                                            tag:[HeyzapAds defaultTagName]
                                                            andAdditionalParams:nil];
    
    [[MediationAPIClient sharedClient] get:@"mediate"
                                withParams:request.createParams
                                   success:^(NSDictionary *json) {
                                       // Check for tag being enabled here.
      // Need better error checking here.
//        NSString *fetchID = json[@"id"];
                                       HZMediationSessionKey *key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:tag];
                                       self.sessionDictionary[key] = json;
                                       
                                       NSArray *networks = json[@"networks"];
      
//                                       NSError *error;
//                                       HZMediationSession *session = [[HZMediationSession alloc] initWithJSON:json setupMediators:self.setupMediators error:&error];
                                       
                                       
                                       NSMutableOrderedSet *adapters = [NSMutableOrderedSet orderedSet];
                                       for (NSDictionary *network in networks) {
                                           NSString *networkName = network[@"network"];
                                           Class adapter = [HZBaseAdapter adapterClassForName:networkName];
                                           if (adapter && [adapter isSDKAvailable] && [self.setupMediators containsObject:[adapter sharedInstance]]) {
                                               [adapters addObject:[adapter sharedInstance]];
                                           }
                                       }
                                       
                                       NSLog(@"Asked to mediate; showImmediately = %i, chosen adapters = %@",showImmediately, adapters);
                                       NSIndexSet *indexes = [adapters indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
                                           return [adapter supportsAdType:adType];
                                       }];
                                       NSArray *validSDKs = [adapters objectsAtIndexes:indexes];
                                       NSLog(@"After filtering, valid SDKs = %@",validSDKs);
                                       
                                       
                                       
        
                                       [self fetchForType:adType
                                             mediatorList:validSDKs
                                                      tag:tag
                                          showImmediately:showImmediately
                                             fetchTimeout:timeout
                                               sessionKey:key];
                                   } failure:^(NSError *error) {
                                       NSLog(@"Error! Failed to get the list of networks to mediate from Heyzap. Mediation won't be possible. Error = %@,",error);
                                   }];
}

- (void)fetchForType:(HZAdType)type mediatorList:(NSArray *)preferredMediatorList tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout sessionKey:(HZMediationSessionKey *)sessionKey
{
    NSLog(@"Preferred mediator list = %@",preferredMediatorList);
    // Should take an ad unit, and filter out SDKs that don't support that ad unit.
    
    // Find the first SDK that has an ad, and use it
    // This means if e.g. the first 2 networks aren't working, we don't have to wait for a timeout to get to the third.
    if (showImmediately) {
        
        const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
            return [adapter hasAdForType:type tag:tag];
        }];
        
        if (idx != NSNotFound) {
            NSLog(@"Using fast path by skipping to first network with an ad.");
            HZBaseAdapter *adapter = preferredMediatorList[idx];
            [self haveAdapter:adapter showAdOfType:type tag:tag sessionKey:sessionKey];
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL successful = NO;
        for (HZBaseAdapter *adapter in preferredMediatorList) {
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [adapter prefetchForType:type tag:tag];
            });
            
            __block BOOL fetchedWithinTimeout = NO;
            hzWaitUntil(^BOOL{
                fetchedWithinTimeout = [adapter hasAdForType:type tag:tag];
                if (adapter.lastError) {
                    NSLog(@"There was an error w/ the fetch = %@",adapter.lastError);
                }
                return [adapter hasAdForType:type tag:tag] || adapter.lastError != nil; // If it errored, exit early.
            }, 2);
            
            if (fetchedWithinTimeout) {
                NSLog(@"We fetched within the timeout! Network = %@",[[adapter class] name]);
                successful = YES;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.adsDelegate didReceiveAdWithTag:tag];
                });
                // Send a fetch successful message
                // For just a fetch we can break now.
                if (!showImmediately) {
                    break;
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self haveAdapter:adapter showAdOfType:type tag:tag sessionKey:sessionKey];
                });
                NSLog(@"Mediator %@ is showing an ad",[[adapter class] name]);
                break;
                
                // Send delegate notification about showing an ad.
            } else {
                NSLog(@"The mediator with name = %@ didn't have an ad",[[adapter class] name]);
                // If the mediated SDK errored, reset it and try again. If there's no error, they're probably still busy fetching.
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (adapter.lastError) {
                        adapter.lastError = nil;
                        [adapter prefetchForType:type tag:tag];
                    }
                });
            }
        }
        if (!successful) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self sendFailureMessagesForTag:tag
                            wasAttemptingToShow:showImmediately];
            });
        }
    });
}

- (void)haveAdapter:(HZBaseAdapter *)adapter showAdOfType:(HZAdType)type tag:(NSString *)tag sessionKey:(HZMediationSessionKey *)sessionKey
{
    id sessionData = self.sessionDictionary[sessionKey];
    [self.sessionDictionary removeObjectForKey:sessionKey];
    HZMediationSessionKey *showKey = [sessionKey sessionKeyAfterShowing];
    self.sessionDictionary[showKey] = sessionData;
    
    [adapter showAdForType:type tag:tag];
    [self adapterHadImpression:adapter session:sessionData];
    [self.adsDelegate didShowAdWithTag:tag];
}

- (void)sendFailureMessagesForTag:(NSString *)tag wasAttemptingToShow:(BOOL)tryingToShow
{
    [self.adsDelegate didFailToReceiveAdWithTag:tag];
    if (tryingToShow) {
        [self.adsDelegate didFailToShowAdWithTag:tag andError:nil];
    }
}

// Did receive ad with tag -> Tag always nil (no consistent way to say what tag a fetch is for).
// Did fail to receieve ad with tag -> Tag always nil (no consistent way to say what tag a fetch is for).

// Did hide ad -> Receive callback from individual SDKs about whether

// Dictionary keys
NSString * const kHZAdapterKey = @"name";
NSString * const kHZDataKey = @"data";


HZAdType hzAdTypeFromString(NSString *adUnit) {
    if ([adUnit isEqualToString:@"interstitial"]) {
        return HZAdTypeInterstitial;
    } else if ([adUnit isEqualToString:@"incentivized"]) {
        return HZAdTypeIncentivized;
    } else if ([adUnit isEqualToString:@"video"]) {
        return HZAdTypeVideo;
    }
    // hmm
    NSLog(@"Invalid ad unit");
    abort();
}

#pragma mark - Querying adapters

- (BOOL)isAvailableForAdUnitType:(HZAdType)adType tag:(NSString *)tag
{
    NSSet *readyAdapters = [self.setupMediators objectsPassingTest:^BOOL(HZBaseAdapter * adapter, BOOL *stop) {
        return [adapter hasAdForType:adType tag:tag];
    }];
    return [readyAdapters count] != 0;
}

#pragma mark - Adapter Callbacks

- (void)adapterHadImpression:(HZBaseAdapter *)adapter session:(id)sessionData
{
    
    HZMediationSessionKey *key = [[self.sessionDictionary keysOfEntriesPassingTest:^BOOL(HZMediationSessionKey *key, id obj, BOOL *stop) {
        return key.hasBeenShown;
    }] anyObject]; // Should be just 1 key that is being shown at a time.
    
    if (key) {
        // Use session Data to send stuff like the impression ID and such.
        [[MediationAPIClient sharedClient] post:@"impression" withParams:nil success:^(id json) {
            NSLog(@"impression was successful");
        } failure:^(NSError *error) {
            NSLog(@"impression failed");
        }];
    }
    
}

/**
 *   We do not get this callback from several networks, so we can't rely on it.
 *
 *  @param adapter The adapter showing the ad.
 */
- (void)adapterWasClicked:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [[self.sessionDictionary keysOfEntriesPassingTest:^BOOL(HZMediationSessionKey *key, id obj, BOOL *stop) {
        return key.hasBeenShown;
    }] anyObject]; // Should be just 1 key that is being shown at a time.
    
    if (key) {
        //        id sessionData = self.sessionDictionary[key];
        [[MediationAPIClient sharedClient] post:@"click" withParams:nil success:^(id json) {
            NSLog(@"click was successful");
        } failure:^(NSError *error) {
            NSLog(@"Click failed");
        }];
    }
}

- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter
{
    NSLog(@"Adapter dismissed ad");
    // Store the last session we called show for, so we can have the tag.
    HZMediationSessionKey *key = [[self.sessionDictionary keysOfEntriesPassingTest:^BOOL(HZMediationSessionKey *key, id obj, BOOL *stop) {
        return key.hasBeenShown;
    }] anyObject]; // Should be just 1 key that is being shown at a time.
    
    [self.sessionDictionary removeObjectForKey:key];
    
    
    [self.adsDelegate didHideAdWithTag:nil];
}

#pragma mark - Incentivized Callbacks

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self.incentivizedDelegate didCompleteAd];
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self.incentivizedDelegate didFailToCompleteAd];
}

@end
