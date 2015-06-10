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
#import "HZAbstractHeyzapAdapter.h"
#import "HZHeyzapAdapter.h"
#import "HZAdColonyAdapter.h"
#import "HZVungleAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZFacebookAdapter.h"
#import "HZMediationAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZMediationConstants.h"
#import "HZAdFetchRequest.h"
#import "HeyzapAds.h"

// Util
#import "HZDispatch.h"
#import "HZDelegateProxy.h"
#import "HZAdModel.h"
#import "HZUtils.h"
#import "HZAdsManager.h"

// Session
#import "HZMediationSessionKey.h"
#import "HZMediationSession.h"

// Metrics
#import "HZMediationConstants.h"
#import "HZDevice.h"

#import "HZiAdBannerAdapter.h"
#import "HZiAdAdapter.h"
#import "HZBannerAdOptions_Private.h"
#import "HZMediationStarter.h"

#define HZMediationCustomPublisherDataKey @"custom_publisher_data"

@interface HeyzapMediation()

@property (nonatomic, strong) NSSet *setupMediators;
@property (nonatomic, strong) NSSet *setupMediatorClasses;

@property (nonatomic, strong) NSMutableDictionary *sessionDictionary;

@property (nonatomic, strong) NSString *countryCode;

@property (nonatomic, strong) NSDate *lastInterstitialVideoShownDate;

@property (nonatomic, strong) HZDelegateProxy *interstitialDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *incentivizedDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *videoDelegateProxy;

@property (nonatomic, strong) void (^networkCallbackBlock)(NSString *network, NSString *callback);
@property (nonatomic, strong) NSMutableDictionary *networkListeners;
@property (nonatomic) dispatch_queue_t fetchQueue;
@property (nonatomic) dispatch_queue_t sdkStartQueue;
@property (nonatomic) dispatch_queue_t pausableMainQueue;
@property (nonatomic) BOOL pausableQueueIsPaused;

@property (nonatomic, strong) HZMediationStarter *starter;

@property (nonatomic) HZMediationStartStatus startStatus;
@property (nonatomic) BOOL hasLoadedFromCache;

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
        _setupMediators = [NSSet set];
        _setupMediatorClasses = [NSSet set];
        _sessionDictionary = [NSMutableDictionary dictionary];
        _interstitialDelegateProxy = [[HZDelegateProxy alloc] init];
        _incentivizedDelegateProxy = [[HZDelegateProxy alloc] init];
        _videoDelegateProxy = [[HZDelegateProxy alloc] init];
        self.fetchQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_CONCURRENT);
        self.sdkStartQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_SERIAL);
        
        self.pausableMainQueue = dispatch_queue_create("com.heyzap.sdk.mediation.pausable_main", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.pausableMainQueue, dispatch_get_main_queue());
        
        self.startStatus = HZMediationStartStatusNotStarted;
        self.starter = [[HZMediationStarter alloc] initWithStartingDelegate:self];
    }
    return self;
}

#pragma mark - Getters / Setters

- (void)setStartStatus:(HZMediationStartStatus)startStatus {
    // Disallow transitioning from started to failure/not started.
    if (_startStatus == HZMediationStartStatusSuccess) {
        return;
    } else {
        _startStatus = startStatus;
    }
}

#pragma mark - Setup

- (void)start {
    HZILog(@"The following SDKs have been detected = %@",[[self class] commaSeparatedAdapterList]);
    [self.starter start];
}

- (void)pauseExpensiveWork {
    if (!self.pausableQueueIsPaused) {
        self.pausableQueueIsPaused = YES;
        dispatch_suspend(self.pausableMainQueue);
    }
}

- (void)resumeExpensiveWork {
    if (self.pausableQueueIsPaused) {
        self.pausableQueueIsPaused = NO;
        dispatch_resume(self.pausableMainQueue);
    }
}

- (void)startWithDictionary:(NSDictionary *)dictionary fromCache:(BOOL)fromCache {
    self.countryCode = [HZDictionaryUtils hzObjectForKey:@"countryCode"
                                                 ofClass:[NSString class]
                                                 default:@"zz" // Unknown or invalid; the server also uses this.
                                                withDict:dictionary];
    NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:dictionary];
    [NSOrderedSet orderedSetWithArray:networks];
    if (networks && ![HeyzapMediation isOnlyHeyzapSDK]) {
        [self setupMediators:networks];
    } else if (!networks){
        HZDLog(@"Error! Failed to get networks from Heyzap; mediation won't be possible. `networks` was invalid");
    }
    
    // converts string like "{\"test\":\"foo\"}" to dictionary
    NSString * customPublisherDataString = [HZDictionaryUtils hzObjectForKey:HZMediationCustomPublisherDataKey ofClass:[NSString class] default: nil withDict:dictionary];
    if(customPublisherDataString == nil) {
        _customPublisherData = nil;
    } else {
        NSError *error;
        NSData *objectData = [customPublisherDataString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:&error];
        _customPublisherData = (error ? nil : json);
    }
    
    if(!fromCache){
     [[NSNotificationCenter defaultCenter] postNotificationName:kHeyzapAdsCustomPublisherDataRefreshedNotification object:nil userInfo:_customPublisherData];
    }
}

- (void)didFailStartRequest {
    self.startStatus = HZMediationStartStatusFailure;
}

- (void)fetchForAdType:(HZAdType)adType tag:(NSString *)tag additionalParams:(NSDictionary *)additionalParams completion:(void (^)(BOOL result, NSError *error))completion
{
    // People are likely to call fetch immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fetchForAdType:adType tag:tag additionalParams:additionalParams completion:completion];
        });
        return;
    }
    
    HZShowOptions *options = [HZShowOptions new];
    options.tag = tag;
    options.completion = completion;
    
    [self mediateForAdType:adType showImmediately:NO additionalParams:additionalParams options:options];
}

- (void)autoFetchInterstitial
{
    if (![[HZAdsManager sharedManager] isOptionEnabled: HZAdOptionsDisableAutoPrefetching]) {
        HZShowOptions *options = [HZShowOptions new];
        
        [self mediateForAdType:HZAdTypeInterstitial
               showImmediately:NO
              additionalParams:nil
                       options:options];
    }
}

// Dictionary keys
NSString * const kHZAdapterKey = @"name";
NSString * const kHZDataKey = @"data";

- (void)setupMediators:(NSArray *)mediatorJSON
{
    dispatch_async(self.sdkStartQueue, ^{
        NSMutableSet *setupMediators = [NSMutableSet set];
        NSMutableSet *setupMediatorClasses = [NSMutableSet set];
        
        for (NSDictionary *mediator in mediatorJSON) {
            NSString *mediatorName = mediator[kHZAdapterKey];
            Class mediatorClass = [HZBaseAdapter adapterClassForName:mediatorName];
            
            if ([self.setupMediatorClasses containsObject:mediatorClass]) {
                HZDLog(@"We've already setup this mediator class %@; skipping this one.",mediatorClass);
                continue;
            }
            
            NSDictionary *mediatorInfo = mediator[kHZDataKey];
            dispatch_sync(self.pausableMainQueue, ^{
                if (mediatorClass && mediatorInfo && [mediatorClass isSDKAvailable]) {
                    HZDLog(@"Enabling adapter = %@",mediatorClass);
                    
                    NSError *credentialError = [mediatorClass enableWithCredentials:mediatorInfo];
                    if (!credentialError) {
                        HZBaseAdapter *adapter = [mediatorClass sharedInstance];
                        adapter.delegate = self;
                        [setupMediators addObject:adapter];
                        [setupMediatorClasses addObject:mediatorClass];
                    } else {
                        HZELog(@"Error setting up 3rd-party SDK. Error = %@",credentialError);
                    }
                } else {
                    HZELog(@"Unavailable mediator %@",[mediatorClass name]);
                }
            });
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.startStatus = HZMediationStartStatusSuccess;
            
            self.setupMediatorClasses = [self.setupMediatorClasses setByAddingObjectsFromSet:setupMediatorClasses];
            self.setupMediators = [self.setupMediators setByAddingObjectsFromSet:setupMediators];
            
            HZILog(@"Setup mediators = %@",setupMediators);
            if ([self.setupMediators count] != 0) {
                [self autoFetchInterstitial];
            }
        });
    });
}


#pragma mark - Ads

- (void)showAdForAdUnitType:(HZAdType)adType additionalParams:(NSDictionary *)additionalParams options:(HZShowOptions *)options
{
    if (self.pausableQueueIsPaused) {
        NSLog(@"Attempted to call show when the SDK is paused. Ignoring this request.");
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Attempted to show an ad when the SDK is paused."}];
        [[self delegateForAdType:adType] didFailToShowAdWithTag:options.tag andError:error];
        if (options.completion) { options.completion(NO,error); }
        return;
    }
    [self mediateForAdType:adType
           showImmediately:YES
          additionalParams:additionalParams
                   options:options];
}

// `mediateForSessionKey` and this method looks up the session.
- (void)mediateForAdType:(HZAdType)adType showImmediately:(BOOL)showImmediately additionalParams:(NSDictionary *)additionalParams options:(HZShowOptions *)options
{
    NSString *adUnit = NSStringFromAdType(adType);
    
    // If we have an existing, matching session we don't need to make another call to /mediate.
    HZMediationSessionKey *key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:options.tag];
    HZMediationSession *session = self.sessionDictionary[key];
    if (session && showImmediately && !additionalParams) {
        [self fetchForSession:session showImmediately:YES sessionKey:key options:options];
        return;
    }
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:[HZMediationConstants creativeTypesForAdType:adType]
                                                                         adUnit:adUnit
                                                                            tag:options.tag
                                                                    auctionType:HZAuctionTypeMixed
                                                            andAdditionalParams:additionalParams];
    
    NSDictionary *const mediateParams = request.createParams;
    
    dispatch_async(self.fetchQueue, ^{
        [[HZMediationAPIClient sharedClient] GET:@"mediate"
                                      parameters:mediateParams
                                         success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
                                             
                                             HZMediationSessionKey *key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:options.tag];
                                             
                                             NSError *error;
                                             HZMediationSession *session = [[HZMediationSession alloc] initWithJSON:json mediateParams:mediateParams setupMediators:self.setupMediators adType:adType tag:options.tag error:&error];
                                             
                                             if (session) {
                                                 self.sessionDictionary[key] = session;
                                                 
                                                 [self fetchForSession:session
                                                       showImmediately:showImmediately
                                                            sessionKey:key
                                                               options:options];
                                             } else {
                                                 [self sendFailureMessagesForAdType:adType wasAttemptingToShow:showImmediately underlyingError:error options:options];
                                             }
                                             
                                             
                                         } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                                             [self sendFailureMessagesForAdType:adType wasAttemptingToShow:showImmediately underlyingError:error options:options];
                                             HZELog(@"Error! Failed to get the list of networks to mediate from Heyzap. Mediation won't be possible. Error = %@,",error);
                                         }];
    });
    
    
}



- (void)fetchForSession:(HZMediationSession *)session showImmediately:(BOOL)showImmediately sessionKey:(HZMediationSessionKey *)sessionKey options:(HZShowOptions *)options
{
    NSString *tag = session.tag;
    
    const NSTimeInterval timeout = showImmediately ? 2 : 12;
    const NSTimeInterval pollInterval = showImmediately ? 0.5 : 3;
    
    NSArray *const preferredMediatorList = ({
        NSArray *mediatorList;
        if (showImmediately) {
            mediatorList = [[session availableAdapters:self.lastInterstitialVideoShownDate] array];
        } else {
            mediatorList = [session.chosenAdapters array]; // If we're not showing an ad right now, give all networks a chance to fetch (a network filtered out by interstitial rate limiting at fetch-time might be eligible at show-time)
        }
        mediatorList;
    });
    
    HZAdType type = session.adType;
    HZDLog(@"Preferred mediator list = %@",preferredMediatorList);
    
    // Find the first SDK that has an ad, and use it
    // This means if e.g. the first 2 networks aren't working, we don't have to wait for a timeout to get to the third.
    if (showImmediately) {
        HZBaseAdapter *adapter = [session firstAdapterWithAd:self.lastInterstitialVideoShownDate];
        if (adapter) {
            [self haveAdapter:adapter showAdForSession:session sessionKey:sessionKey options:options];
            return;
        }
    }
    
    dispatch_async(self.fetchQueue, ^{
        BOOL successful = NO;
        int ordinal = 0;
        for (HZBaseAdapter *adapter in preferredMediatorList) {
            
            dispatch_sync(self.pausableMainQueue, ^{
                [adapter prefetchForType:type tag:tag];
            });
            
            __block BOOL fetchedWithinTimeout = NO;
            hzWaitUntilInterval(pollInterval, ^BOOL{
                fetchedWithinTimeout = [adapter hasAdForType:type tag:tag];
                if ([adapter lastErrorForAdType:type]) {
                    HZELog(@"There was an error w/ the fetch = %@",[adapter lastErrorForAdType:type]);
                }
                return [adapter hasAdForType:type tag:tag] || [adapter lastErrorForAdType:type] != nil; // If it errored, exit early.
            }, timeout);
            
            __block BOOL isRateLimited = NO;
            dispatch_sync(dispatch_get_main_queue(), ^{
                isRateLimited = [session adapterIsRateLimited:adapter lastInterstitialVideoShown:self.lastInterstitialVideoShownDate];
            });
            // Consider rate limited networks as failing
            // Technically what we could do is, if no other networks succeed, wait until the rate limit is up and send a delegate callback + block callback then.
            // This adds alot of complexity though, and it causes several minute wait periods for a fetch failure.
            // (This should rarely happen anyway since Heyzap isn't video rate limited).
            if (isRateLimited && fetchedWithinTimeout) {
                continue;
            }
            
            if (fetchedWithinTimeout) {
                HZDLog(@"We fetched within the timeout! Network = %@",[[adapter class] name]);
                successful = YES;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (options.completion) { options.completion(YES,nil); }
                    [[self delegateForAdType:type] didReceiveAdWithTag:tag];
                    [session reportFetchWithSuccessfulAdapter:adapter];
                });
                if (showImmediately) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self haveAdapter:adapter showAdForSession:session sessionKey:sessionKey options:options];
                    });
                    HZDLog(@"Mediator %@ is showing an ad",[[adapter class] name]);
                }
                
                break;
                
                // Send delegate notification about showing an ad.
            } else {
                HZDLog(@"The mediator with name = %@ didn't have an ad",[[adapter class] name]);
                
                // If the mediated SDK errored, reset it and try again. If there's no error, they're probably still busy fetching.
                dispatch_sync(self.pausableMainQueue, ^{
                    if ([adapter lastErrorForAdType:type]) {
                        NSString *reason;
                        if ([adapter lastErrorForAdType:type].userInfo[NSUnderlyingErrorKey]) {
                            reason = ((NSError *) [adapter lastErrorForAdType:type].userInfo[NSUnderlyingErrorKey]).localizedDescription;
                        } else {
                            reason = [adapter lastErrorForAdType:type].localizedDescription;
                        }
                        [adapter clearErrorForAdType:type];
                        [adapter prefetchForType:type tag:tag];
                    }
                });
            }
            
            ordinal++;
        }
        if (!successful) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [session reportFetchWithSuccessfulAdapter:nil];
                [self.sessionDictionary removeObjectForKey:sessionKey];
                [self sendFailureMessagesForAdType:type
                               wasAttemptingToShow:showImmediately
                                   underlyingError:nil
                                           options:options];
            });
        }
    });
}

unsigned long long const adapterDidShowAdTimeout = 1.5;

- (void)haveAdapter:(HZBaseAdapter *)adapter showAdForSession:(HZMediationSession *)session sessionKey:(HZMediationSessionKey *)key options:(HZShowOptions *)options
{
    [self.sessionDictionary removeObjectForKey:key];
    
    HZMediationSessionKey *showKey = [key sessionKeyAfterRequestingShow];
    self.sessionDictionary[showKey] = session;
    
    if ([adapter isVideoOnlyNetwork] && session.adType == HZAdTypeInterstitial) {
        self.lastInterstitialVideoShownDate = [NSDate date];
    }
    
    [adapter showAdForType:session.adType options:options];
    
    // Check if the session has responded yet.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(adapterDidShowAdTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self checkIfSession:session isUnshownWithKey:showKey adapter:adapter showOptions:options];
    });
}


- (void)sendFailureMessagesForAdType:(HZAdType)adType wasAttemptingToShow:(BOOL)tryingToShow underlyingError:(NSError *)underlyingError options:(HZShowOptions *)options
{
    NSDictionary *userInfo = underlyingError ? @{NSUnderlyingErrorKey: underlyingError} : nil;
    NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:userInfo];
    
    [[self delegateForAdType:adType] didFailToReceiveAdWithTag:options.tag];
    if (options.completion) { options.completion(NO,error); }
    if (tryingToShow) {
        [[self delegateForAdType:adType] didFailToShowAdWithTag:options.tag andError:error];
    }
}

#pragma mark - Querying adapters

- (BOOL)isAvailableForAdUnitType:(const HZAdType)adType tag:(NSString *)tag
{
    tag = tag ?: [HeyzapAds defaultTagName];
    
    return [[self availableAdaptersForAdType:adType tag:tag] count] != 0;
}

- (BOOL)isAvailableForAdUnitType:(const HZAdType)adType tag:(NSString *)tag network:(HZBaseAdapter *const)network {
    tag = tag ?: [HeyzapAds defaultTagName];
    return [[self availableAdaptersForAdType:adType tag:tag] containsObject:network];
}

- (NSOrderedSet *)availableAdaptersForAdType:(const HZAdType)adType tag:(NSString *)tag {
    HZParameterAssert(tag);
    
    HZMediationSessionKey *const key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:tag];
    HZMediationSession *const session = self.sessionDictionary[key];
    if (!session) {
        return [NSOrderedSet orderedSet];
    }
    
    NSOrderedSet *const availableAdapters = [session availableAdapters:self.lastInterstitialVideoShownDate];
    
    NSIndexSet *const adapterIndexes = [availableAdapters indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter * adapter, NSUInteger idx, BOOL *stop) {
        return [adapter hasAdForType:adType tag:tag];
    }];
    
    return [NSOrderedSet orderedSetWithArray:[availableAdapters objectsAtIndexes:adapterIndexes]];
}

#pragma mark - Adapter Callbacks

- (void)adapterDidShowAd:(HZBaseAdapter *)adapter {
    HZMediationSessionKey *key = [self sessionKeyForAdState:HZAdStateRequestedShow];
    
    if (key) {
        HZMediationSession *session = self.sessionDictionary[key];
        [session reportImpressionForAdapter:adapter];
        
        [self.sessionDictionary removeObjectForKey:key];
        HZMediationSessionKey *showKey = [key sessionKeyAfterShown];
        self.sessionDictionary[showKey] = session;
        
        [[self delegateForAdType:session.adType] didShowAdWithTag:session.tag];
    } else {
        HZDLog(@"The network %@ reported that it showed an ad, but we weren't expecting this.",adapter.name);
    }
}

- (void)checkIfSession:(HZMediationSession *)session isUnshownWithKey:(HZMediationSessionKey *)key adapter:(HZBaseAdapter *)adapter showOptions:(HZShowOptions *)showOptions {
    HZParameterAssert(session);
    HZParameterAssert(key);
    HZParameterAssert(key.adState == HZAdStateRequestedShow);
    
    HZMediationSession *unshownSession = self.sessionDictionary[key];
    if (unshownSession == session) {
        NSError *showError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:
            @{
              NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Adapter %@ was asked to show an ad, but we didn't Heyzap didn't get a callback from that network reporting that it did so within %llu seconds. Assuming it failed and sending a didFail callback",adapter.name, adapterDidShowAdTimeout]}];
        
        // Assume if we haven't shown yet, the show is broken and we should just log an error.
        [self.sessionDictionary removeObjectForKey:key];
        [[self delegateForAdType:session.adType] didFailToShowAdWithTag:session.tag andError:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{}]];
        if (showOptions.completion) { showOptions.completion(NO,showError); }
    }
}

// did Fail To Show?

- (HZMediationSessionKey *)sessionKeyForAdState:(const HZAdState)state
{
    return [[self.sessionDictionary keysOfEntriesPassingTest:^BOOL(HZMediationSessionKey *key, id obj, BOOL *stop) {
        return key.adState == state;
    }] anyObject]; // Should be just 1 key that is being shown at a time.
}

/**
 *   We do not get this callback from several networks, so we can't rely on it.
 *
 *  @param adapter The adapter showing the ad.
 */
- (void)adapterWasClicked:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self sessionKeyForAdState:HZAdStateShown];
    
    if (key) {
        HZMediationSession *session = self.sessionDictionary[key];
        [session reportClickForAdapter:adapter];
        [[self delegateForAdType:key.adType] didClickAdWithTag:key.tag];
    }
}

// Potential issue: If an adapter fails to send us a callback we might not remove the sessionKey from the dictionary
- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self sessionKeyForAdState:HZAdStateShown];
    
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
    HZMediationSessionKey *key = [self sessionKeyForAdState:HZAdStateShown];
    if (key) {
        [[self delegateForAdType:key.adType] willStartAudio];
    }
}
- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self sessionKeyForAdState:HZAdStateShown];
    if (key) {
        [[self delegateForAdType:key.adType] didFinishAudio];
    }
    
    
}

#pragma mark - Incentivized Specific

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self sessionKeyForAdState:HZAdStateShown];
    if (key) {
        [[self delegateForAdType:HZAdTypeIncentivized] didCompleteAdWithTag:key.tag];
    }
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self sessionKeyForAdState:HZAdStateShown];
    if (key) {
        [[self delegateForAdType:HZAdTypeIncentivized] didFailToCompleteAdWithTag:key.tag];
    }
}

#pragma mark - Misc

+ (NSString *)commaSeparatedAdapterList
{
    // Profiling showed this to take > 1 ms; it's doing a decent amount of work checking if all the classes exist.
    static NSString *commaSeparatedAdapters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *adapterNames = [NSMutableArray array];
        for (Class adapterClass in [HZBaseAdapter allAdapterClasses]) {
            if ([adapterClass isSDKAvailable]) {
                [adapterNames addObject:[adapterClass name]];
            }
        }
        commaSeparatedAdapters = [adapterNames componentsJoinedByString:@","];
    });
    
    return commaSeparatedAdapters;
}

static BOOL forceOnlyHeyzapSDK = NO;
+ (void)forceOnlyHeyzapSDK {
    forceOnlyHeyzapSDK = YES;
}

+ (BOOL)isOnlyHeyzapSDK
{
    static BOOL isOnlyHeyzap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isOnlyHeyzap = [[self availableNonHeyzapAdapters] count] == 0 || forceOnlyHeyzapSDK;
    });
    return isOnlyHeyzap;
}


+ (NSSet *)availableAdaptersWithHeyzap:(BOOL)includeHeyzap
{
    return [[HZBaseAdapter allAdapterClasses] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class adapterClass, NSDictionary *bindings) {
        return (includeHeyzap || ![adapterClass isHeyzapAdapter]) && [adapterClass isSDKAvailable];
    }]];
}

+ (NSSet *)availableNonHeyzapAdapters
{
    return [self availableAdaptersWithHeyzap:NO];
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
        case HZAdTypeBanner: {
            // Ignored; banners have a different delegate system.
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
        case HZAdTypeBanner: {
            // Banners use a different delegate system.
            return nil;
        }
    }
}

const NSTimeInterval bannerTimeout = 10;
const NSTimeInterval bannerPollInterval = 1;

- (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAdapter *adapter))completion {
    HZParameterAssert(options);
    HZParameterAssert(completion);
    // People are likely to call fetch immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestBannerWithOptions:options completion:completion];
        });
        return;
    }
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:@[@"banner"]
                                                                         adUnit:@"banner"
                                                                            tag:options.tag
                                                                    auctionType:HZAuctionTypeMixed
                                                            andAdditionalParams:(options.networkName ? @{@"networks" : options.networkName} : @{})];
    
    NSDictionary *const mediateParams = request.createParams;
    
    
    dispatch_async(self.fetchQueue, ^{
        [[HZMediationAPIClient sharedClient] GET:@"mediate" parameters:mediateParams success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
            
            // This should be factored out into a general way of saying "does the ad network have credentials for X ad format?
            NSSet *const setupBannerMediators = [self.setupMediators objectsPassingTest:^BOOL(HZBaseAdapter *adapter, BOOL *stop) {
                return [adapter hasBannerCredentials];
            }];
            
            NSError *error;
            HZMediationSession *const session = [[HZMediationSession alloc] initWithJSON:json mediateParams:mediateParams setupMediators:setupBannerMediators adType:HZAdTypeBanner tag:request.tag error:&error];
            if (error) {
                NSError *mediationError = [[self class] bannerErrorWithDescription:@"Couldn't create HZMediationSession" underlyingError:error];
                completion(mediationError, nil);
                return;
            }
            
            dispatch_async(self.fetchQueue, ^{
                for (HZBaseAdapter *baseAdapter in session.chosenAdapters) {
                    __block HZBannerAdapter *bannerAdapter;
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        bannerAdapter = [baseAdapter fetchBannerWithOptions:options reportingDelegate:self];
                    });
                    
                    __block BOOL isAvailable = NO;
                    hzWaitUntilInterval(bannerPollInterval, ^BOOL{
                        isAvailable = [bannerAdapter isAvailable];
                        if (bannerAdapter.lastError) {
                            HZELog(@"Ad Network %@ had an error loading a banner: %@",baseAdapter.name, bannerAdapter.lastError);
                        }
                        return isAvailable || (bannerAdapter.lastError != nil);
                    }, bannerTimeout);
                    
                    if (isAvailable) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            bannerAdapter.session = session;
                            [session reportFetchWithSuccessfulAdapter:baseAdapter];
                            completion(nil, bannerAdapter);
                        });
                        
                        break;
                    } else if (baseAdapter == [session.chosenAdapters lastObject]) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [session reportFetchWithSuccessfulAdapter:nil];
                            completion([[self class] bannerErrorWithDescription:@"None of the mediated ad networks had a banner available" underlyingError:nil], nil);
                        });
                    }
                    
                }
            });
            
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            NSError *mediationError = [[self class] bannerErrorWithDescription:@"Error communicating with Heyzap's servers" underlyingError:error];
            completion(mediationError, nil);
        }];
    });
    
    
    // Session gets attached to what? To the adapter?
    // Maybe to the wrapper?
    
}

+ (NSError *)bannerErrorWithDescription:(NSString *)description underlyingError:(NSError *)underlyingError {
    HZParameterAssert(description);
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:userInfo];
}

// TODO *** need to implement functionality so that the ad loading only counts as an impression after it is added to the screen, which is mildly tricky (best I have so far is an NStimer to check the superview property).

- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter hadImpressionForSession:(HZMediationSession *)session {
    [session reportImpressionForAdapter:bannerAdapter.parentAdapter];
}
- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter wasClickedForSession:(HZMediationSession *)session {
    [session reportClickForAdapter:bannerAdapter.parentAdapter];
}

- (void)setDelegate:(id)delegate forNetwork:(NSString *)network {
    if (network == nil) return;
    
    if (delegate == nil) {
        [self.networkListeners removeObjectForKey: [network lowercaseString]];
    } else {
        [self.networkListeners setObject:delegate forKey: [network lowercaseString]];
    }
}

- (id)delegateForNetwork:(NSString *)network {
    if (network == nil) {
        return nil;
    }
    
    return [self.networkListeners objectForKey: [network lowercaseString]];
}

- (BOOL) isNetworkInitialized:(NSString *)network {
    if (network == nil) {
        return NO;
    }
    
    for(HZBaseAdapter *adapter in self.setupMediators) {
        if ([[adapter name] isEqualToString: [network lowercaseString]]) {
            return YES;
        }
    }
    
    return NO;
}

- (void) setNetworkCallbackBlock: (void (^)(NSString *network, NSString *callback))block {
    _networkCallbackBlock = block;
}

- (void) sendNetworkCallback: (NSString *) callback forNetwork: (NSString *) network {
    if (_networkCallbackBlock != nil) {
        _networkCallbackBlock(network, callback);
    }
}

@end