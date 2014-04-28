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
#import "HZMediationAPIClient.h"
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

typedef NS_ENUM(NSUInteger, HZMediationStartStatus) {
    HZMediationStartStatusNotStarted,
    HZMediationStartStatusFailure,
    HZMediationStartStatusSuccess,
};

@interface HeyzapMediation() <HZMediationAdapterDelegate>

@property (nonatomic, strong) NSSet *setupMediators;

HZAdType hzAdTypeFromString(NSString *adUnit);
NSString * NSStringFromAdType(HZAdType type);

@property (nonatomic, strong) NSMutableDictionary *sessionDictionary;

@property (nonatomic, strong) NSString *countryCode;

@property (nonatomic) BOOL startHasBeenCalled;
@property (nonatomic) HZMediationStartStatus startStatus;

@property (nonatomic, strong) DelegateProxy *interstitialDelegateProxy;
@property (nonatomic, strong) DelegateProxy *incentivizedDelegateProxy;
@property (nonatomic, strong) DelegateProxy *videoDelegateProxy;

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
    });
    
    return mediator;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _setupMediators = [[NSMutableSet alloc] init];
        _sessionDictionary = [NSMutableDictionary dictionary];
        _interstitialDelegateProxy = [[DelegateProxy alloc] init];
        _incentivizedDelegateProxy = [[DelegateProxy alloc] init];
        _videoDelegateProxy = [[DelegateProxy alloc] init];
    }
    return self;
}

#pragma mark - Setup

- (void)start
{
    // Prevent duplicate start calls.
    if (self.startHasBeenCalled) {
        return;
    }
    self.startHasBeenCalled = YES;
    
    HZDLog(@"The following SDKs have been detected = %@",[[self class] commaSeparatedAdapterList]);
    
    [[HZMediationAPIClient sharedClient] get:@"start" withParams:nil success:^(NSDictionary *json) {
        self.countryCode = [HZDictionaryUtils hzObjectForKey:@"countryCode"
                                                     ofClass:[NSString class]
                                                     default:@"zz" // Unknown or invalid; the server also uses this.
                                                    withDict:json];
        NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:json];
        [NSOrderedSet orderedSetWithArray:networks];
        if (networks) {
            [self setupMediators:networks];
        } else {
            HZDLog(@"Error! Failed to get networks from Heyzap; mediation won't be possible. `networks` was invalid");
        }
        self.startStatus = [self.setupMediators count] == 0 ? HZMediationStartStatusFailure : HZMediationStartStatusSuccess;
    } failure:^(NSError *error) {
        self.startStatus = HZMediationStartStatusFailure;
        HZDLog(@"Error! Failed to get networks from Heyzap. Mediation won't be possible. Error = %@,",error);
    }];
}

- (void)fetchForAdType:(HZAdType)adType tag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion
{
    // People are likely to call fetch immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fetchForAdType:adType tag:tag completion:completion];
        });
        return;
    }
    
    tag = tag ?: [HeyzapAds defaultTagName];
    [self mediateForAdType:adType tag:tag showImmediately:NO fetchTimeout:10 completion:completion];
}

- (void)autoFetchInterstitial
{
    [self mediateForAdType:HZAdTypeInterstitial
                       tag:nil
           showImmediately:NO
              fetchTimeout:10
                completion:nil];
}

// Dictionary keys
NSString * const kHZAdapterKey = @"name";
NSString * const kHZDataKey = @"data";

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
                HZELog(@"Error setting up 3rd-party SDK. Error = %@",credentialError);
            }
        } else {
            HZELog(@"Unavailable mediator %@",[mediatorClass name]);
        }
    }
    self.setupMediators = setupMediators;
    HZILog(@"Setup mediators = %@",setupMediators);
    if ([self.setupMediators count] != 0) {
        [self autoFetchInterstitial];
    }
}


#pragma mark - Ads

- (void)showAdForAdUnitType:(HZAdType)adType tag:(NSString *)tag completion:(void (^)(BOOL, NSError *))completion
{
    tag = tag ?: [HeyzapAds defaultTagName];
    
    [self mediateForAdType:adType
                       tag:tag
           showImmediately:YES
              fetchTimeout:2
                completion:completion];
}

// `mediateForSessionKey` and this method looks up the session. 
- (void)mediateForAdType:(HZAdType)adType tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout completion:(void (^)(BOOL result, NSError *error))completion
{
    if (tag == nil) {
        tag = [HeyzapAds defaultTagName];
    }
    NSString *adUnit = NSStringFromAdType(adType);
    
    // If we have an existing, matching session we don't need to make another call to /mediate.
    HZMediationSessionKey *key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:tag];
    HZMediationSession *session = self.sessionDictionary[key];
    if (session && showImmediately) {
        [self fetchForSession:session showImmediately:YES fetchTimeout:timeout sessionKey:key completion:completion];
        return;
    }
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:[HZMediationConstants creativeTypesForAdType:adType]
                                                                         adUnit:adUnit
                                                                            tag:[HeyzapAds defaultTagName]
                                                            andAdditionalParams:nil];
    
    
    
    [[HZMediationAPIClient sharedClient] get:@"mediate"
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
                                       } else {
                                           [self sendFailureMessagesForTag:tag adType:adType wasAttemptingToShow:showImmediately completionBlock:completion underlyingError:error];
                                       }
        
                                       
                                   } failure:^(NSError *error) {
                                       [self sendFailureMessagesForTag:tag adType:adType wasAttemptingToShow:showImmediately completionBlock:completion underlyingError:error];
                                       HZELog(@"Error! Failed to get the list of networks to mediate from Heyzap. Mediation won't be possible. Error = %@,",error);
                                   }];
}



- (void)fetchForSession:(HZMediationSession *)session showImmediately:(BOOL)showImmediately fetchTimeout:(const NSTimeInterval)timeout sessionKey:(HZMediationSessionKey *)sessionKey completion:(void (^)(BOOL result, NSError *error))completion
{
    NSString *tag = session.tag;
    NSArray *preferredMediatorList = [session.chosenAdapters array];
    HZAdType type = session.adType;
    HZDLog(@"Preferred mediator list = %@",preferredMediatorList);
    
    // Find the first SDK that has an ad, and use it
    // This means if e.g. the first 2 networks aren't working, we don't have to wait for a timeout to get to the third.
    if (showImmediately) {
        HZBaseAdapter *adapter = [session firstAdapterWithAd];
        if (adapter) {
            if (completion) { completion(YES,nil); }
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
                if ([adapter lastErrorForAdType:type]) {
                    HZELog(@"There was an error w/ the fetch = %@",[adapter lastErrorForAdType:type]);
                }
                return [adapter hasAdForType:type tag:tag] || [adapter lastErrorForAdType:type] != nil; // If it errored, exit early.
            }, timeout);
            
            if (fetchedWithinTimeout) {
                HZDLog(@"We fetched within the timeout! Network = %@",[[adapter class] name]);
                successful = YES;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (completion) { completion(YES,nil); }
                    [[self delegateForAdType:type] didReceiveAdWithTag:tag];
                    [session reportSuccessfulFetchUpToAdapter:adapter];
                });
                if (showImmediately) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self haveAdapter:adapter showAdForSession:session sessionKey:sessionKey];
                    });
                    HZDLog(@"Mediator %@ is showing an ad",[[adapter class] name]);
                }
                
                break;
                
                // Send delegate notification about showing an ad.
            } else {
                HZDLog(@"The mediator with name = %@ didn't have an ad",[[adapter class] name]);
                // If the mediated SDK errored, reset it and try again. If there's no error, they're probably still busy fetching.
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if ([adapter lastErrorForAdType:type]) {
                        [adapter clearErrorForAdType:type];
                        [adapter prefetchForType:type tag:tag];
                    }
                });
            }
        }
        if (!successful) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.sessionDictionary removeObjectForKey:sessionKey];
                [self sendFailureMessagesForTag:tag
                                         adType:type
                            wasAttemptingToShow:showImmediately
                                completionBlock:completion
                                underlyingError:nil];
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
    [session reportImpressionForAdapter:adapter];
    [[self delegateForAdType:session.adType] didShowAdWithTag:session.tag];
}


- (void)sendFailureMessagesForTag:(NSString *)tag adType:(HZAdType)adType wasAttemptingToShow:(BOOL)tryingToShow completionBlock:(void (^)(BOOL result, NSError *error))completion underlyingError:(NSError *)underlyingError
{
    NSDictionary *userInfo = underlyingError ? @{NSUnderlyingErrorKey: underlyingError} : nil;
    NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:userInfo];
    
    [[self delegateForAdType:adType] didFailToReceiveAdWithTag:tag];
    if (completion) { completion(NO,error); }
    if (tryingToShow) {
        [[self delegateForAdType:adType] didFailToShowAdWithTag:tag
                                                       andError:error];
    }
}

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

- (HZMediationSessionKey *)currentShownSessionKey
{
    return [[self.sessionDictionary keysOfEntriesPassingTest:^BOOL(HZMediationSessionKey *key, id obj, BOOL *stop) {
        return key.hasBeenShown;
    }] anyObject]; // Should be just 1 key that is being shown at a time.
}

/**
 *   We do not get this callback from several networks, so we can't rely on it.
 *
 *  @param adapter The adapter showing the ad.
 */
- (void)adapterWasClicked:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self currentShownSessionKey];
    
    if (key) {
        HZMediationSession *session = self.sessionDictionary[key];
        [session reportClickForAdapter:adapter];
    }
}

// Potential issue: If an adapter fails to send us a callback we might not remove the sessionKey from the dictionary
- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self currentShownSessionKey];
    
    if (key) {
        [self.sessionDictionary removeObjectForKey:key];
        [[self delegateForAdType:key.adType] didHideAdWithTag:key.tag];
    }
    
    if (key.adType == HZAdTypeInterstitial && [key.tag isEqualToString:[HeyzapAds defaultTagName]]) {
        [self autoFetchInterstitial];
    }
}

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self currentShownSessionKey];
    if (key) {
        [[self delegateForAdType:key.adType] willStartAudio];
    }
}
- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self currentShownSessionKey];
    if (key) {
        [[self delegateForAdType:key.adType] didFinishAudio];
    }
}

#pragma mark - Incentivized Specific

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [[self delegateForAdType:HZAdTypeIncentivized] didCompleteAd];
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [[self delegateForAdType:HZAdTypeIncentivized] didFailToCompleteAd];
}

#pragma mark - Misc

+ (NSString *)commaSeparatedAdapterList
{
    NSMutableArray *adapterNames = [NSMutableArray array];
    for (Class adapterClass in [HZBaseAdapter allAdapterClasses]) {
        if ([adapterClass isSDKAvailable]) {
            [adapterNames addObject:[adapterClass name]];
        }
    }
    return [adapterNames componentsJoinedByString:@","];
}

+ (BOOL)isOnlyHeyzapSDK
{
    NSSet *availableNonHeyzapAdapters = [[HZBaseAdapter allAdapterClasses] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class adapterClass, NSDictionary *bindings) {
        return ![[adapterClass name] isEqualToString:kHZAdapterHeyzap] && [adapterClass isSDKAvailable];
    }]];
    return [availableNonHeyzapAdapters count] == 0;
}

#pragma mark - Setters/Getters for delegates

- (void)setDelegate:(id<HZAdsDelegate>)delegate forAdType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            self.interstitialDelegateProxy.forwardingTarget = delegate;
            break;
        }
        case HZAdTypeIncentivized: {
            self.incentivizedDelegateProxy.forwardingTarget = delegate;
            break;
        }
        case HZAdTypeVideo: {
            self.videoDelegateProxy.forwardingTarget = delegate;
            break;
        }
    }
}

- (id)delegateForAdType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            return self.interstitialDelegateProxy;
            break;
        }
        case HZAdTypeIncentivized: {
            return self.incentivizedDelegateProxy;
            break;
        }
        case HZAdTypeVideo: {
            return self.videoDelegateProxy;
            break;
        }
    }
}

@end
