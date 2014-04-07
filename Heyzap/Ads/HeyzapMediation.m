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
    NSLog(@"Is only heyzap SDK = %i",[[self class] isOnlyHeyzapSDK]);
    
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

- (void)fetchForAdType:(HZAdType)adType tag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion
{
    tag = tag ?: [HeyzapAds defaultTagName];
    [self mediateForAdType:adType tag:tag showImmediately:NO fetchTimeout:10 completion:completion];
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
              fetchTimeout:10
                completion:nil];
}


#pragma mark - Ads


// Potentially I should start up a timer here to try again if we aren't setup yet.
// Downside to that is that we could show an ad like 10s after they asked for it.

- (void)showAdForAdUnitType:(HZAdType)adType tag:(NSString *)tag completion:(void (^)(BOOL, NSError *))completion
{
    tag = tag ?: [HeyzapAds defaultTagName];
    
    [self mediateForAdType:adType
                       tag:tag
           showImmediately:YES
              fetchTimeout:2
                completion:completion];
}

- (void)mediateForAdType:(HZAdType)adType tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout completion:(void (^)(BOOL result, NSError *error))completion
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
                                       
                                       HZMediationSessionKey *key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:tag];
      
                                       NSError *error;
                                       HZMediationSession *session = [[HZMediationSession alloc] initWithJSON:json setupMediators:self.setupMediators adType:adType tag:tag error:&error];
                                       
                                       if (session) {
                                           self.sessionDictionary[key] = session;
                                           
                                           [self fetchForSession:session
                                                 showImmediately:showImmediately
                                                    fetchTimeout:timeout
                                                      sessionKey:key
                                                      completion:completion];
                                       }
        
                                       
                                   } failure:^(NSError *error) {
                                       if (completion) { completion(NO,[NSError errorWithDomain:@"heyzap" code:1 userInfo:@{NSUnderlyingErrorKey: error}]); }
                                       [self sendFailureMessagesForTag:tag wasAttemptingToShow:showImmediately];
                                       NSLog(@"Error! Failed to get the list of networks to mediate from Heyzap. Mediation won't be possible. Error = %@,",error);
                                   }];
}

// I *think* that both the show and fetch completion blocks can be combined here.

- (void)fetchForSession:(HZMediationSession *)session showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout sessionKey:(HZMediationSessionKey *)sessionKey completion:(void (^)(BOOL result, NSError *error))completion
{
    NSString *tag = session.tag;
    NSArray *preferredMediatorList = [session.chosenAdapters array];
    HZAdType type = session.adType;
    NSLog(@"Preferred mediator list = %@",preferredMediatorList);
    // Should take an ad unit, and filter out SDKs that don't support that ad unit.
    
    // Find the first SDK that has an ad, and use it
    // This means if e.g. the first 2 networks aren't working, we don't have to wait for a timeout to get to the third.
    if (showImmediately) {
        HZBaseAdapter *adapter = [session firstAdapterWithAd];
        if (adapter) {
            if (completion) { completion(YES,nil); }
            NSLog(@"Using fast path by skipping to first network with an ad.");
            [self haveAdapter:adapter showAdForSession:session sessionKey:sessionKey];
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
                    if (completion) { completion(YES,nil); }
                    [self.adsDelegate didReceiveAdWithTag:tag];
                });
                // Send a fetch successful message
                // For just a fetch we can break now.
                if (!showImmediately) {
                    break;
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self haveAdapter:adapter showAdForSession:session sessionKey:sessionKey];
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
                if (completion) { completion(NO,[NSError errorWithDomain:@"heyzap" code:1 userInfo:nil]); }
                [self sendFailureMessagesForTag:tag
                            wasAttemptingToShow:showImmediately];
            });
        }
    });
}

- (void)haveAdapter:(HZBaseAdapter *)adapter showAdForSession:(HZMediationSession *)session sessionKey:(HZMediationSessionKey *)key
{
    [self.sessionDictionary removeObjectForKey:key];
    
    
    HZMediationSessionKey *showKey = [key sessionKeyAfterShowing];
    self.sessionDictionary[showKey] = session;
    
    [adapter showAdForType:session.adType tag:session.tag];
    [session reportImpression];
    [self.adsDelegate didShowAdWithTag:session.tag];
}


// Possibly this should take the completion block param too, and a potential NSUnderlying error?
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

#pragma mark - Querying adapters

- (BOOL)isAvailableForAdUnitType:(HZAdType)adType tag:(NSString *)tag
{
    tag = tag ?: [HeyzapAds defaultTagName];
    NSSet *readyAdapters = [self.setupMediators objectsPassingTest:^BOOL(HZBaseAdapter * adapter, BOOL *stop) {
        return [adapter hasAdForType:adType tag:tag];
    }];
    return [readyAdapters count] != 0;
}

#pragma mark - Adapter Callbacks

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
        HZMediationSession *session = self.sessionDictionary[key];
        [session reportClick];
    }
}

// Potential issue: If an adapter fails to send us a callback we might not remove the sessionKey from the dictionary
- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter
{
    NSLog(@"Adapter dismissed ad");
    // Store the last session we called show for, so we can have the tag.
    HZMediationSessionKey *key = [[self.sessionDictionary keysOfEntriesPassingTest:^BOOL(HZMediationSessionKey *key, id obj, BOOL *stop) {
        return key.hasBeenShown;
    }] anyObject]; // Should be just 1 key that is being shown at a time.
    
    
    if (key) {
        NSLog(@"Did lookup session for dismiss");
        [self.sessionDictionary removeObjectForKey:key];
        
        [self.adsDelegate didHideAdWithTag:nil];
    }
}

#pragma mark - Incentivized Specific

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self.incentivizedDelegate didCompleteAd];
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self.incentivizedDelegate didFailToCompleteAd];
}

#pragma mark - Enum Support

NSString * NSStringFromAdType(HZAdType type)
{
    switch (type) {
        case HZAdTypeInterstitial: {
            return @"interstitial";
            break;
        }
        case HZAdTypeIncentivized: {
            return @"incentivized";
            break;
        }
        case HZAdTypeVideo: {
            return @"video";
            break;
        }
    }
}

HZAdType hzAdTypeFromString(NSString *adUnit) {
    if ([adUnit isEqualToString:@"incentivized"]) {
        return HZAdTypeIncentivized;
    } else if ([adUnit isEqualToString:@"video"]) {
        return HZAdTypeVideo;
    } else {
        return HZAdTypeInterstitial;
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

+ (BOOL)isOnlyHeyzapSDK
{
    NSSet *availableNonHeyzapAdapters = [[HZBaseAdapter allAdapterClasses] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class adapterClass, NSDictionary *bindings) {
        return ![[adapterClass name] isEqualToString:kHZAdapterHeyzap] && [adapterClass isSDKAvailable];
    }]];
    return [availableNonHeyzapAdapters count] == 0;
}

@end
