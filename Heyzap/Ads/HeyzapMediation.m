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
#import "HZMediationAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZMediationConstants.h"
#import "HZAdFetchRequest.h"
#import "HeyzapAds.h"

// Util
#import "HZDispatch.h"
#import "HZDelegateProxy.h"
#import "HZAdModel.h"

// Session
#import "HZMediationSessionKey.h"
#import "HZMediationSession.h"

// Metrics
#import "HZMetrics.h"
#import "HZMetricsAdStub.h"
#import "HZMediationConstants.h"
#import "HZDevice.h"

typedef NS_ENUM(NSUInteger, HZMediationStartStatus) {
    HZMediationStartStatusNotStarted,
    HZMediationStartStatusFailure,
    HZMediationStartStatusSuccess,
};

@interface HeyzapMediation()

@property (nonatomic, strong) NSSet *setupMediators;

@property (nonatomic, strong) NSMutableDictionary *sessionDictionary;

@property (nonatomic, strong) NSString *countryCode;

@property (nonatomic) BOOL startHasBeenCalled;
@property (nonatomic) HZMediationStartStatus startStatus;

@property (nonatomic, strong) HZDelegateProxy *interstitialDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *incentivizedDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *videoDelegateProxy;

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
        _interstitialDelegateProxy = [[HZDelegateProxy alloc] init];
        _incentivizedDelegateProxy = [[HZDelegateProxy alloc] init];
        _videoDelegateProxy = [[HZDelegateProxy alloc] init];
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
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        self.startStatus = HZMediationStartStatusFailure;
        HZDLog(@"Error! Failed to get networks from Heyzap. Mediation won't be possible. Error = %@,",error);
    }];
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

    tag = tag ?: [HeyzapAds defaultTagName];
    [self mediateForAdType:adType tag:tag showImmediately:NO fetchTimeout:10 additionalParams:additionalParams completion:completion];
}

- (void)autoFetchInterstitial
{
    [self mediateForAdType:HZAdTypeInterstitial
                       tag:nil
           showImmediately:NO
              fetchTimeout:10
          additionalParams:nil
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

- (void)showAdForAdUnitType:(HZAdType)adType tag:(NSString *)tag additionalParams:(NSDictionary *)additionalParams completion:(void (^)(BOOL, NSError *))completion
{
    tag = tag ?: [HeyzapAds defaultTagName];

    HZMetricsAdStub *stub = [[HZMetricsAdStub alloc] initWithTag:tag adUnit:NSStringFromAdType(adType)];
    [[HZMetrics sharedInstance] logShowAdWithObject:stub network:nil];
    [[HZMetrics sharedInstance] logTimeSinceStartFor:kTimeFromStartToShowAdKey withProvider:stub network:nil];

    [self mediateForAdType:adType
                       tag:tag
           showImmediately:YES
              fetchTimeout:2
          additionalParams:additionalParams
                completion:completion];
}

// `mediateForSessionKey` and this method looks up the session. 
- (void)mediateForAdType:(HZAdType)adType tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout additionalParams:(NSDictionary *)additionalParams completion:(void (^)(BOOL result, NSError *error))completion
{
    tag = [HZAdModel normalizeTag:tag];
    NSString *adUnit = NSStringFromAdType(adType);
    
    // If we have an existing, matching session we don't need to make another call to /mediate.
    HZMediationSessionKey *key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:tag];
    HZMediationSession *session = self.sessionDictionary[key];
    if (session && showImmediately && !additionalParams) {
        [self fetchForSession:session showImmediately:YES fetchTimeout:timeout sessionKey:key completion:completion];
        return;
    }
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:[HZMediationConstants creativeTypesForAdType:adType]
                                                                         adUnit:adUnit
                                                                            tag:tag
                                                                    auctionType:HZAuctionTypeMixed
                                                            andAdditionalParams:additionalParams];
    
    
    
    [[HZMediationAPIClient sharedClient] get:@"mediate"
                                withParams:request.createParams
                                   success:^(NSDictionary *json) {
                                       
                                       HZMediationSessionKey *key = [[HZMediationSessionKey alloc] initWithAdType:adType tag:tag];
      
                                       NSError *error;
                                       HZMediationSession *session = [[HZMediationSession alloc] initWithJSON:json setupMediators:self.setupMediators adType:adType tag:tag error:&error];
                                       
                                       if (session) {
                                           self.sessionDictionary[key] = session;

                                           [[HZMetrics sharedInstance] logMetricsEvent:@"impression_id" value:session.impressionID withProvider:session network:nil];

                                           [self fetchForSession:session
                                                 showImmediately:showImmediately
                                                    fetchTimeout:timeout
                                                      sessionKey:key
                                                      completion:completion];
                                       } else {
                                           [self sendFailureMessagesForTag:tag adType:adType wasAttemptingToShow:showImmediately completionBlock:completion underlyingError:error];
                                       }
        
                                       
                                   } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                                       [self sendFailureMessagesForTag:tag adType:adType wasAttemptingToShow:showImmediately completionBlock:completion underlyingError:error];
                                       HZELog(@"Error! Failed to get the list of networks to mediate from Heyzap. Mediation won't be possible. Error = %@,",error);
                                   }];
}



- (void)fetchForSession:(HZMediationSession *)session showImmediately:(BOOL)showImmediately fetchTimeout:(const NSTimeInterval)timeout sessionKey:(HZMediationSessionKey *)sessionKey completion:(void (^)(BOOL result, NSError *error))completion
{
    NSString *tag = session.tag;
    NSArray *preferredMediatorList = [session.chosenAdapters array];
    HZAdType type = session.adType;
    NSString *connectivity = [[HZDevice currentDevice] HZConnectivityType];
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
    
    NSLog(@"Preferred mediator list = %@",preferredMediatorList);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL successful = NO;
        int ordinal = 0;
        for (HZBaseAdapter *adapter in preferredMediatorList) {
            NSString *network = [[adapter class] name];
            __block CFTimeInterval startTime;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                // start of fetch metrics
                [[HZMetrics sharedInstance] logMetricsEvent:kNetworkVersionKey value:adapter.sdkVersion withProvider:session network:network];
                [[HZMetrics sharedInstance] logMetricsEvent:kOrdinalKey value:@(ordinal) withProvider:session network:network];
                [[HZMetrics sharedInstance] logMetricsEvent:kAdUnitKey value:session.adUnit withProvider:session network:network];
                [[HZMetrics sharedInstance] logMetricsEvent:kConnectivityKey value:connectivity withProvider:session network:network];
                [[HZMetrics sharedInstance] logMetricsEvent:kFetchKey value:@1 withProvider:session network:network];
                [[HZMetrics sharedInstance] logFetchTimeWithObject:session network:network];
                startTime = CACurrentMediaTime();

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

            CFTimeInterval elapsedSeconds = CACurrentMediaTime() - startTime;
            int64_t elaspsedMilliseconds = lround(elapsedSeconds*1000);

            if (fetchedWithinTimeout) {
                NSLog(@"We fetched within the timeout! Network = %@",[[adapter class] name]);
                [[HZMetrics sharedInstance] logMetricsEvent:kFetchDownloadTimeKey value:@(elaspsedMilliseconds) withProvider:session network:network];
                successful = YES;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (completion) { completion(YES,nil); }
                    [[self delegateForAdType:type] didReceiveAdWithTag:tag];
                    [session reportSuccessfulFetchUpToAdapter:adapter];
                });
                if (showImmediately) {
                    [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kNotCachedAndAttemptedFetchSuccessValue withProvider:session network:network];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self haveAdapter:adapter showAdForSession:session sessionKey:sessionKey];
                    });
                    HZDLog(@"Mediator %@ is showing an ad",[[adapter class] name]);
                }
                
                break;
                
                // Send delegate notification about showing an ad.
            } else {
                HZDLog(@"The mediator with name = %@ didn't have an ad",[[adapter class] name]);

                [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailedKey value:@(1) withProvider:session network:network];
                if (showImmediately) {
                    [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kNotCachedAndAttemptedFetchFailedValue withProvider:session network:network];
                }

                // If the mediated SDK errored, reset it and try again. If there's no error, they're probably still busy fetching.
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if ([adapter lastErrorForAdType:type]) {
                        NSString *reason;
                        if ([adapter lastErrorForAdType:type].userInfo[NSUnderlyingErrorKey]) {
                            reason = ((NSError *) [adapter lastErrorForAdType:type].userInfo[NSUnderlyingErrorKey]).localizedDescription;
                        } else {
                            reason = [adapter lastErrorForAdType:type].localizedDescription;
                        }
                        reason = [reason substringToIndex:MIN([reason length], (unsigned) 25)]; // timecube column is varchar(25)
                        [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailReasonKey value:reason withProvider:session network:network];
                        [adapter clearErrorForAdType:type];
                        [adapter prefetchForType:type tag:tag];
                    } else if (!connectivity){
                        [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailReasonKey value:kNoConnectivityValue withProvider:session network:network];
                        if (showImmediately) {
                            [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kNoConnectivityValue withProvider:session network:network];
                        }
                    }
                });
            }

            ordinal++;
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

static int totalImpressions = 0;

- (void)haveAdapter:(HZBaseAdapter *)adapter showAdForSession:(HZMediationSession *)session sessionKey:(HZMediationSessionKey *)key
{
    [self.sessionDictionary removeObjectForKey:key];
    
    HZMediationSessionKey *showKey = [key sessionKeyAfterShowing];
    self.sessionDictionary[showKey] = session;

    [adapter showAdForType:session.adType tag:session.tag];
    [session reportImpressionForAdapter:adapter];
    [[self delegateForAdType:session.adType] didShowAdWithTag:session.tag];

    NSString *network = [adapter name];
    [[HZMetrics sharedInstance] logTimeSinceFetchFor:kTimeFromFetchToImpressionKey withProvider:session network:network];
    [[HZMetrics sharedInstance] logMetricsEvent:kNthAdKey value:@(++totalImpressions) withProvider:session network:network];
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
        BOOL available = [adapter hasAdForType:adType tag:tag];

        NSString *network = [adapter name];
        HZMetricsAdStub *stub = [[HZMetricsAdStub alloc] initWithTag:tag adUnit:NSStringFromAdType(adType)];
        [[HZMetrics sharedInstance] logMetricsEvent:kIsAvailableCalledKey value:@1 withProvider:stub network:network];
        [[HZMetrics sharedInstance] logTimeSinceFetchFor:kIsAvailableTimeSincePreviousFetchKey withProvider:stub network:network];
        [[HZMetrics sharedInstance] logIsAvailable:available withProvider:stub network:network];
        [[HZMetrics sharedInstance] logMetricsEvent:kNetworkVersionKey value:adapter.sdkVersion withProvider:stub network:network];

        return available;
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
        [[self delegateForAdType:key.adType] didClickAdWithTag:key.tag];
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

- (UIViewController *)viewControllerForPresentingAd {
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

#pragma mark - Incentivized Specific

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self currentShownSessionKey];
    if (key) {
        [[self delegateForAdType:HZAdTypeIncentivized] didCompleteAdWithTag:key.tag];
    }
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    HZMediationSessionKey *key = [self currentShownSessionKey];
    if (key) {
        [[self delegateForAdType:HZAdTypeIncentivized] didFailToCompleteAdWithTag:key.tag];
    }
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

static BOOL forceOnlyHeyzapSDK = NO;
+ (void)forceOnlyHeyzapSDK {
    forceOnlyHeyzapSDK = YES;
}

+ (BOOL)isOnlyHeyzapSDK
{
    return [[self availableNonHeyzapAdapters] count] == 0 || forceOnlyHeyzapSDK;
}

+ (NSSet *)availableNonHeyzapAdapters
{
    return [[HZBaseAdapter allAdapterClasses] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class adapterClass, NSDictionary *bindings) {
        return ![adapterClass isHeyzapAdapter] && [adapterClass isSDKAvailable];
    }]];
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
