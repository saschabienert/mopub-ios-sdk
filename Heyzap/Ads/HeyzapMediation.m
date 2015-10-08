//
//  HeyzapMediation.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HeyzapMediation.h"
#import "HZBaseAdapter.h"
#import "HZMediationAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZMediationConstants.h"
#import "HZAdFetchRequest.h"
#import "HeyzapAds.h"
#import "HZTestActivityViewController.h"
#import "HZShowOptions_Private.h"
#import "HZFetchOptions_HeyzapMediationPrivate.h"

// Util
#import "HZDispatch.h"
#import "HZDelegateProxy.h"
#import "HZAdModel.h"
#import "HZUtils.h"
#import "HZAdsManager.h"

// Event Reporting
#import "HZMediationEventReporter.h"

// Metrics
#import "HZMediationConstants.h"
#import "HZDevice.h"

#import "HZBannerAdOptions_Private.h"

// Helper classes
#import "HZMediationStarter.h"
#import "HZMediationCurrentShownAd.h"
#import "HZMediateRequester.h"
#import "HZMediationLoadManager.h"
#import "HZMediationAvailabilityChecker.h"
#import "HZMediationSettings.h"
#import "HZCachingService.h"
#import "HZMediationInterstitialVideoManager.h"
#import "HZCachingService.h"
#import "HZMediationPersistentConfig.h"

// Exchange
#import "HZHeyzapExchangeAdapter.h"
#import "HZHeyzapExchangeBannerAdapter.h"

// Segmentation
#import "HZImpressionHistory.h"

@interface HeyzapMediation()

@property (nonatomic, strong) NSSet<HZBaseAdapter *> *setupMediators;
@property (nonatomic, strong) NSSet<Class> *setupMediatorClasses;
@property (nonatomic, strong) NSSet<Class> *erroredMediatiorClasses;

@property (nonatomic, strong) HZDelegateProxy *interstitialDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *incentivizedDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *videoDelegateProxy;

@property (nonatomic, strong) void (^networkCallbackBlock)(NSString *network, NSString *callback);
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *networkListeners;
@property (nonatomic) dispatch_queue_t fetchQueue;
@property (nonatomic) dispatch_queue_t sdkStartQueue;
@property (nonatomic) dispatch_queue_t pausableMainQueue;
@property (nonatomic) BOOL pausableQueueIsPaused;

// Child objects HeyzapMediation uses to avoid putting everything in this file
@property (nonatomic, strong) HZCachingService *cachingService;
@property (nonatomic, strong) HZMediationStarter *starter;
@property (nonatomic, strong) HZMediateRequester *mediateRequester;
@property (nonatomic, strong) HZMediationLoadManager *loadManager;
@property (nonatomic, strong) HZMediationAvailabilityChecker *availabilityChecker;
@property (nonatomic, strong) HZMediationSettings *settings;
@property (nonatomic, strong) HZSegmentationController *segmentationController;
@property (nonatomic, strong) HZMediationInterstitialVideoManager *interstitialVideoManager;

@property (nonatomic) HZMediationStartStatus startStatus;

@property (nonatomic) BOOL hasLoadManagerSetupSucceeded;
@property (nonatomic) BOOL hasSegmentationSetupFinished;

// State
@property (nonatomic) HZMediationCurrentShownAd *currentShownAd;

- (void)sendShowFailureMessagesWithShowOptions:(HZShowOptions *)options error:(NSError *)underlyingError;

@end

@implementation HeyzapMediation

#pragma mark - Initialization

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
        _erroredMediatiorClasses = [NSSet set];
        _interstitialDelegateProxy = [[HZDelegateProxy alloc] init];
        _incentivizedDelegateProxy = [[HZDelegateProxy alloc] init];
        _videoDelegateProxy = [[HZDelegateProxy alloc] init];
        self.fetchQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_CONCURRENT);
        self.sdkStartQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_SERIAL);
        
        self.pausableMainQueue = dispatch_queue_create("com.heyzap.sdk.mediation.pausable_main", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.pausableMainQueue, dispatch_get_main_queue());
        
        self.startStatus = HZMediationStartStatusNotStarted;

        _settings = [[HZMediationSettings alloc] init];
        _segmentationController = [[HZSegmentationController alloc] init];
        _cachingService = [[HZCachingService alloc] init];
        _starter = [[HZMediationStarter alloc] initWithStartingDelegate:self cachingService:_cachingService];
        _mediateRequester = [[HZMediateRequester alloc] initWithDelegate:self cachingService:_cachingService];
        _persistentConfig = [[HZMediationPersistentConfig alloc] initWithCachingService:_cachingService isTestApp:[HZDevice isHeyzapTestApp]];
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HZILog(@"The following SDKs have been detected = %@",[[self class] commaSeparatedAdapterList]);
        [self.starter start];
        [self.mediateRequester start];
    });
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

- (void)addCredentialsToAdapters:(NSDictionary *const __nonnull)startDict {
    NSArray *const networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:startDict];
    if (!networks) {
        HZELog(@"Invalid /start response; missing 'networks' in JSON");
    }
    
    for (NSDictionary *networkInfo in networks) {
        NSString *const network = [HZDictionaryUtils objectForKey:@"name" ofClass:[NSString class] dict:networkInfo];
        
        NSDictionary *const credentials = ({
            // Remove credentials that are empty string. Empty string was sent for backwards compatability, but now that the SDK has true support for optional credentials we can just filter it.
            NSDictionary *originalCreds = [HZDictionaryUtils objectForKey:@"data" ofClass:[NSDictionary class] dict:networkInfo];
            NSDictionary *const filteredCredentials = [HZDictionaryUtils dictionaryByFilteringDictionary:originalCreds withBlock:^BOOL(NSString *key, NSString *credential, BOOL *stop) {
                return ![credential isEqualToString:@""];
            }];
            filteredCredentials;
        });
        
        if (network && credentials) {
            HZBaseAdapter *const adapter = [[HZBaseAdapter adapterClassForName:network] sharedAdapter];
            adapter.credentials = credentials; // The adapter will prevent overriding existing credentials, to prevent them changing between the cached and non-cached /start response.
        } else {
            HZELog(@"Invalid network in /start response");
        }
    }
}

- (void)startWithDictionary:(NSDictionary *const __nonnull)dictionary fromCache:(const BOOL)fromCache {
    HZILog(@"Mediation starting from %@", fromCache ? @"cache" : @"network");
    [[self settings] setupWithDict:dictionary fromCache:fromCache];
    [self addCredentialsToAdapters:dictionary];
    [self.segmentationController setupFromMediationStart:dictionary completion:^void(BOOL successful){
        HZILog(@"Segmentation started from %@ %@successfully", fromCache ? @"cache" : @"network", successful ? @"" : @"un");
        self.hasSegmentationSetupFinished = YES;
    }];
    
    NSError *error;
    if (!self.loadManager) {
        self.loadManager = [[HZMediationLoadManager alloc] initWithLoadData:dictionary[@"loader"] delegate:self persistentConfig:self.persistentConfig segmentationController:self.segmentationController error:&error];
        if (error || !self.loadManager) {
            HZELog(@"Error initializing network preloader. Mediation won't be possible. %@",error);
        } else {
            HZILog(@"Load manager setup from %@", fromCache ? @"cache" : @"network");
            self.hasLoadManagerSetupSucceeded = YES;
        }
    } else {
        if (![self.loadManager refreshWithLoadData:dictionary[@"loader"] error:&error] || error) {
            HZELog(@"Error refreshing network preloader. Mediation may be out of date. %@", error);
        }
    }
}

- (void)receivedStartHeaders:(NSDictionary *)headers {
    if (headers[@"heyzapLogging"]) {
        NSLog(@"heyzapLogging header present; enabling verbose logging");
        [HZLog setDebugLevel:HZDebugLevelVerbose];
    }
    
    if (headers[@"showMediationDebugSuite"]) {
        // Allow delaying the time to show the mediation debug suite to accommodate long app load times.
        NSString *delayString = headers[@"showMediationDebugSuiteDelay"];
        NSInteger delayTime = delayString ? [delayString integerValue] : 7;
        
        NSLog(@"showMediationDebugSuite header present; showing mediation debug suite after a delay");
        NSLog(@"showMediationDebugSuiteDelay = %li",(long)delayTime);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showTestActivity];
        });
    }
}

- (void) setHasLoadManagerSetupSucceeded:(BOOL)hasLoadManagerSetupSucceeded {
    _hasLoadManagerSetupSucceeded = hasLoadManagerSetupSucceeded;
    [self evaluateStartStatus];
}
- (void) setHasSegmentationSetupFinished:(BOOL)hasSegmentationSetupFinished {
    _hasSegmentationSetupFinished = hasSegmentationSetupFinished;
    [self evaluateStartStatus];
}
- (void) evaluateStartStatus {
    @synchronized(self) {
        if (self.hasLoadManagerSetupSucceeded && self.hasSegmentationSetupFinished && self.startStatus != HZMediationStartStatusSuccess) {
            self.startStatus = HZMediationStartStatusSuccess;
            HZILog(@"Mediation started successfully.");
            [self autoFetchAdType:HZAdTypeInterstitial tag:nil];
        }
    }
}


#pragma mark - Fetching

- (void) fetchWithOptions:(HZFetchOptions *)fetchOptions
{
    HZParameterAssert(fetchOptions);
    HZParameterAssert(fetchOptions.requestingAdType);
    
    // People are likely to call fetch immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        HZILog(@"Mediation not started yet when a fetch was called. Will retry.");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fetchWithOptions:fetchOptions];
        });
        return;
    }
    
    HZParameterAssert(self.loadManager);
    
    HZILog(@"Mediation: fetchWithOptions called. adType: %@ tag: %@", NSStringFromAdType(fetchOptions.requestingAdType), fetchOptions.tag);
    
    if(fetchOptions.requestingAdType == HZAdTypeIncentivized && ![[self settings] shouldAllowIncentivizedAd]) {
        HZILog(@"Fetch failing because this user has reached their daily limit for incentivized views.");
        [[self delegateForAdType:fetchOptions.requestingAdType] didFailToReceiveAdWithTag:fetchOptions.tag];
        if(fetchOptions.completion) {
            fetchOptions.completion(NO, [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"This user has reached their daily limit for incentivized ad views."}]);
        }
        return;
    }
    
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:fetchOptions.additionalParameters];
    
    // fetch all creativeTypes that can be shown via the requesting adType.
    // interstitial video handling:
    //  - don't fetch interstitial video if it's completely disabled
    //  - fetch interstitial video even if it's currently under a timeout, so it's available later should the timeout expire
    //      - (the delegate callbacks / completion blocks (didReceiveAdWithTag: / didFailToReceiveAdWithTag:) won't be called
    //        for interstitial video if the timeout is still in effect when the fetch finishes)
    NSMutableSet *creativeTypesToFetch = hzCreativeTypesPossibleForAdType(fetchOptions.requestingAdType);
    if (fetchOptions.requestingAdType == HZAdTypeInterstitial && ![self.interstitialVideoManager interstitialVideoEnabled]){
        HZILog(@"Interstitial video is disabled, so this fetch will not fetch a video ad.");
        [creativeTypesToFetch removeObject:@(HZCreativeTypeVideo)];
    }
    fetchOptions.creativeTypesToFetch = creativeTypesToFetch;
    
    for (NSNumber * creativeTypeToFetch in fetchOptions.creativeTypesToFetch) {
        HZCreativeType creativeType = hzCreativeTypeFromNSNumber(creativeTypeToFetch);
        [self.loadManager fetchCreativeType:creativeType fetchOptions:fetchOptions optionalForcedNetwork:optionalForcedNetwork notifyDelegate:YES];
    }
}

- (void)autoFetchAdType:(HZAdType)adType tag:(NSString *)tag {
    if (![[HZAdsManager sharedManager] isOptionEnabled: HZAdOptionsDisableAutoPrefetching]) {
        HZFetchOptions *fetchOptions = [HZFetchOptions new];
        fetchOptions.tag = tag;
        fetchOptions.requestingAdType = adType;
        fetchOptions.additionalParameters = nil;
        fetchOptions.completion = ^void (BOOL result, NSError *error){
            if(adType == HZAdTypeIncentivized && ![[self settings] shouldAllowIncentivizedAd]) {
                // don't keep autofetching if it'll keep failing because of the daily limit
                HZILog(@"Autofetch failing out because it's trying to fetch an incentivized ad when the daily limit has been reached.");
                return;
            }
            
            if (error) {
                HZELog(@"Autofetch had an error, trying again in 10 seconds. Error: %@", error);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self autoFetchAdType:adType tag:tag];
                });
            }
        };
        
        HZILog(@"Autofetching for adType: %@, tag: '%@'", NSStringFromAdType(adType), tag);
        [self fetchWithOptions:fetchOptions];
    }
}


#pragma mark - Fetch (LoadManager) callbacks

- (void)didFetchAdOfCreativeType:(HZCreativeType)creativeType withAdapter:(HZBaseAdapter *)adapter options:(HZFetchOptions *)fetchOptions {
    
    if (![[self settings] tagIsEnabled:fetchOptions.tag]) {
        HZILog(@"Tag '%@' is disabled, so an otherwise successful fetch from %@ is not reporting as a success.", fetchOptions.tag, [adapter humanizedName]);
        [self didFailToFetchAdOfCreativeType:creativeType options:fetchOptions];
    } else if (fetchOptions.requestingAdType == HZAdTypeInterstitial
               && creativeType == HZCreativeTypeVideo
               && ![self.interstitialVideoManager shouldAllowInterstitialVideo]) {
        // we fetched an interstitial video but it can't show at this time. don't report fetch success in this case.
        HZILog(@"Interstitial video settings are blocking an otherwise successful fetch from %@ from reporting as a success.", [adapter humanizedName]);
        [self didFailToFetchAdOfCreativeType:creativeType options:fetchOptions];
    } else {
        @synchronized(fetchOptions) {
            fetchOptions.creativeTypesFetchesFinished = [fetchOptions.creativeTypesFetchesFinished setByAddingObject:@(creativeType)];
            if (!fetchOptions.alreadyNotifiedDelegateOfSuccess){
                HZILog(@"Fetch succeeded. Notifying delegate. creativeType: %@, adapter: %@, tag: %@ requesting adType: %@", NSStringFromCreativeType(creativeType), [adapter humanizedName], fetchOptions.tag, NSStringFromAdType(fetchOptions.requestingAdType));
                fetchOptions.alreadyNotifiedDelegateOfSuccess = YES;
                [[self delegateForAdType:fetchOptions.requestingAdType] didReceiveAdWithTag:fetchOptions.tag];
                if (fetchOptions.completion) { fetchOptions.completion(YES, nil); }
            } else {
                HZILog(@"Fetch succeeded, already notified delegate. creativeType: %@, adapter: %@, tag: %@ requesting adType: %@", NSStringFromCreativeType(creativeType), [adapter humanizedName], fetchOptions.tag, NSStringFromAdType(fetchOptions.requestingAdType));
            }
        }
    }
}

- (void)didFailToFetchAdOfCreativeType:(HZCreativeType)creativeType options:(HZFetchOptions *)fetchOptions {
    @synchronized(fetchOptions) {
        HZILog(@"Fetch failed for creativeType: %@ tag: %@ requesting adType: %@", NSStringFromCreativeType(creativeType), fetchOptions.tag, NSStringFromAdType(fetchOptions.requestingAdType));
        fetchOptions.creativeTypesFetchesFinished = [fetchOptions.creativeTypesFetchesFinished setByAddingObject:@(creativeType)];
        NSMutableSet *creativeTypesLeftToFetch = [fetchOptions.creativeTypesToFetch mutableCopy];
        [creativeTypesLeftToFetch minusSet:fetchOptions.creativeTypesFetchesFinished];
        if ([creativeTypesLeftToFetch count] == 0) {
            HZILog(@"Fetch failed for all creativeTypes. Notifying delegate. tag: %@ requesting adType: %@", fetchOptions.tag, NSStringFromAdType(fetchOptions.requestingAdType));
            NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Heyzap was unable to fetch an ad from any of the available networks for creative types: [%@] and tag: [%@] via ad type: %@.", [ hzMap([fetchOptions.creativeTypesToFetch allObjects], ^NSString *(NSNumber * number){return NSStringFromCreativeType(hzCreativeTypeFromNSNumber(number));}) componentsJoinedByString:@", "], fetchOptions.tag, NSStringFromAdType(fetchOptions.requestingAdType)]}];
            
            [[self delegateForAdType:fetchOptions.requestingAdType] didFailToReceiveAdWithTag:fetchOptions.tag];
            if (fetchOptions.completion) { fetchOptions.completion(NO, error); }
        }
    }
}


#pragma mark - Showing

- (void)showForAdType:(HZAdType)adType additionalParams:(NSDictionary *)additionalParams options:(HZShowOptions *)options
{
    if (!options) {
        options = [HZShowOptions new];
    }
    
    options.requestingAdType = adType;
    
    HZILog(@"Mediation: showForAdType: %@ tag: %@", NSStringFromAdType(adType), options.tag);
    
    NSError *preShowError = [self checkForPreShowError:options.tag adType:adType];
    if (preShowError) {
        [self sendShowFailureMessagesWithShowOptions:options error:preShowError];
        return;
    }
    
    if (self.currentShownAd.isStale) {
        const NSTimeInterval timeSinceShown = [[NSDate date] timeIntervalSinceDate:self.currentShownAd.shownDate];
        HZELog(@"WARNING: It has been %g seconds since Mediation requested an ad be shown from %@, but we've not received an \"ad dismissed\" callback from that network. After %llu seconds we assume an ad is no longer showing for the purposes of allowing a new ad to show, but this means your code will not have received a \"dismiss\" callback. This indicates there is either a bug in mediation, the 3rd party network is not sending callbacks, or your code is interfering with how ads are shown. Please report this issue to support@heyzap.com for investigation.\n\n\n",timeSinceShown, self.currentShownAd.adapter.humanizedName, adStalenessTimeout);
        self.currentShownAd = nil;
    }
    
    // Getting /mediate and sending failure message can be part of the
    // TODO: tell the server if an outdated or cached mediate is being used. Potentially include the outdated time diff.
    NSDictionary *const latestMediate = [self.mediateRequester latestMediate];
    NSDictionary *const latestMediateParams = [self.mediateRequester latestMediateParams];
    if (!latestMediate || !latestMediateParams) {
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Didn't get the waterfall from Heyzap's servers before a request to show an ad was made."}];
        [self sendShowFailureMessagesWithShowOptions:options error:error];
        return;
    }
    
    // update Heyzap Exchange's scores with latest fetched ad scores (ads have their own scores in the exchange, the score currently on the adapter is the per network score all networks have)
    [[HZHeyzapExchangeAdapter sharedAdapter] setAllMediationScoresForReadyAds];
    
    // filter for the forced network, if applicable
    NSSet *adapterClassesToConsider = self.setupMediatorClasses;
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:additionalParams];
    if (optionalForcedNetwork) {
        HZILog(@"Mediation only showing for one adapter: %@", [optionalForcedNetwork humanizedName]);
        adapterClassesToConsider = [adapterClassesToConsider objectsPassingTest:^BOOL(Class klass, BOOL *stop) {
            return klass == optionalForcedNetwork;
        }];
    }
    
    // this returns a set of HZMediationAdapterWithCreativeTypeScore
    NSMutableOrderedSet *adaptersWithScores = [[self.availabilityChecker parseMediateIntoAdaptersForShow:latestMediate validAdapterClasses:adapterClassesToConsider adType:adType] mutableCopy];
    
    // Sort the adapters, largest score first. The objects in the set obtained above contain their creative type and score.
    [self sortAdaptersByScore:adaptersWithScores ifLatestMediateRequires:latestMediate];

    HZMediationAdapterWithCreativeTypeScore *chosenAdapterWithScore = [self.availabilityChecker firstAdapterWithAdForTag:options.tag
                                                                                                      adaptersWithScores:adaptersWithScores
                                                                                                  segmentationController:self.segmentationController];
    
    // Start event reporting
    NSError *eventReporterError;
    NSOrderedSet * plainAdapters = hzMapOrderedSet(adaptersWithScores, ^HZBaseAdapter *(HZMediationAdapterWithCreativeTypeScore * adapterWithScore) { return [adapterWithScore adapter]; });
    
    HZMediationEventReporter *eventReporter = [[HZMediationEventReporter alloc] initWithJSON:latestMediate
                                                                               mediateParams:latestMediateParams
                                                                           potentialAdapters:plainAdapters
                                                                                      adType:adType
                                                                                creativeType:[chosenAdapterWithScore creativeType]
                                                                                         tag:options.tag
                                                                                       error:&eventReporterError];
    
    if (eventReporterError || !eventReporter) {
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{
                                                                                       NSLocalizedDescriptionKey: @"Failed to parse /mediate response",
                                                                                       NSUnderlyingErrorKey:eventReporterError,
                                                                                       }];
        [self sendShowFailureMessagesWithShowOptions:options error:error];
        return;
    }
    
    [eventReporter reportFetchWithSuccessfulAdapter:[chosenAdapterWithScore adapter]];
    if (!chosenAdapterWithScore) {
        NSString *const errorMessage = [NSString stringWithFormat:@"An ad cannot be shown at this time. Either no available networks had an ad or segmentation settings prevented the show. Ad networks we checked: [%@]", [hzMap([plainAdapters array], ^NSString *(HZBaseAdapter *adapter){return [[adapter class] humanizedName];}) componentsJoinedByString:@", "]];
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        [self sendShowFailureMessagesWithShowOptions:options error:error];
        return;
    }
    
    self.currentShownAd = [[HZMediationCurrentShownAd alloc] initWithEventReporter:eventReporter adapter:[chosenAdapterWithScore adapter] options:options];
    
    [self.mediateRequester refreshMediate];
    
    // Show ad
    HZDLog(@"HeyzapMediation: %@ adapter will now show an ad of creativeType: %@. Requested adType: %@ tag: %@", [[chosenAdapterWithScore adapter] name], NSStringFromCreativeType([chosenAdapterWithScore creativeType]), NSStringFromAdType(adType), options.tag);
    [[chosenAdapterWithScore adapter] showAdForCreativeType:[chosenAdapterWithScore creativeType] options:options];
}

- (void) sortAdaptersByScore:(NSMutableOrderedSet *)adaptersWithScores ifLatestMediateRequires:(NSDictionary *)latestMediate {
    BOOL shouldSortAdapters = [[HZDictionaryUtils objectForKey:@"sort" ofClass:[NSNumber class] default:@0 dict:latestMediate] boolValue];
    
    if(shouldSortAdapters) {
        [adaptersWithScores sortUsingComparator:^(HZMediationAdapterWithCreativeTypeScore *obj1, HZMediationAdapterWithCreativeTypeScore *obj2) {
            // [obj2 compare:obj1] will sort highest score first
            return [[obj2 score] compare:[obj1 score]];
        }];
    }
    
    // avoid the loop if we don't want to print the scores
    if([HZLog debugLevel] >= HZDebugLevelVerbose) {
        NSMutableString *scoreStr = [NSMutableString stringWithFormat:@"Waterfall (%@ order): ", shouldSortAdapters ? @"Sorted" : @"UNSORTED"];
        NSNumberFormatter  *formatter = [[NSNumberFormatter alloc] init];
        [formatter setMaximumFractionDigits:4];
        [formatter setNumberStyle:NSNumberFormatterScientificStyle];
        for(HZMediationAdapterWithCreativeTypeScore *adapterWithScore in adaptersWithScores) {
            
            [scoreStr appendFormat:@"[%@ (%@): %@]", [[adapterWithScore adapter] name], NSStringFromCreativeType([adapterWithScore creativeType]), [formatter stringFromNumber:[adapterWithScore score]]];
        }
        
        HZDLog(@"%@",scoreStr);
    }
}

- (NSError *)checkForPreShowError:(NSString *)tag adType:(HZAdType)adType {
    if (self.startStatus != HZMediationStartStatusSuccess) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"SDK hasn't finished starting."}];
    } else if (self.pausableQueueIsPaused) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Attempted to show an ad when the SDK is paused."}];
    } else if ([[[self settings] disabledTags] containsObject:tag]) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Attempted to show an ad with a disabled tag"}];
    } else if (self.currentShownAd && !self.currentShownAd.isStale && !hzCanShowConcurrentlyWithOtherAds(adType)) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"An ad is already shown or attempting to be shown"}];
    } else if ([[self settings] IAPAdsTimeOut] && adType != HZAdTypeIncentivized) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Ads are disabled because of a recent in-app-purchase."}];
    } else if(adType == HZAdTypeIncentivized && ![[self settings] shouldAllowIncentivizedAd]) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"This user has reached their daily limit for incentivized ad views."}];
    }
    
    return nil;
}

- (void)sendShowFailureMessagesWithShowOptions:(HZShowOptions *)options error:(NSError *)underlyingError {
    NSError *error;
    
    if ([[underlyingError domain] isEqualToString:kHZMediationDomain]) {
        error = underlyingError;
        
    } else {
        NSDictionary *userInfo = underlyingError ? @{ NSUnderlyingErrorKey: underlyingError } : nil;
        error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:userInfo];
    }
    
    HZELog(@"Error showing ad = %@", error);
    
    if ([options completion]) {
        options.completion(NO, error);
    }
    
    [[self delegateForAdType:options.requestingAdType] didFailToShowAdWithTag:options.tag andError:error];
}


#pragma mark - Querying adapters

- (BOOL)isAvailableForAdUnitType:(const HZAdType)adType tag:(NSString *)tag {
    tag = [HZAdModel normalizeTag:tag];
    return [[self availableAdaptersForAdType:adType tag:tag] count] != 0;
}

- (BOOL)isAvailableForAdUnitType:(const HZAdType)adType tag:(NSString *)tag network:(HZBaseAdapter *const)network {
    tag = [HZAdModel normalizeTag:tag];
    return [[self availableAdaptersForAdType:adType tag:tag] containsObject:network];
}

- (NSOrderedSet *)availableAdaptersForAdType:(const HZAdType)adType tag:(NSString *)tag {
    NSError *preShowError = [self checkForPreShowError:tag adType:adType];
    if (preShowError || !self.mediateRequester.latestMediate) {
        return [NSOrderedSet orderedSet];
    }
    
    return [self.availabilityChecker availableAndAllowedAdaptersForAdType:adType tag:tag adapters:[NSOrderedSet orderedSetWithSet:self.setupMediators] segmentationController:self.segmentationController];
}


#pragma mark - Adapter Callbacks

const unsigned long long adStalenessTimeout = 15;

- (void)adapterDidShowAd:(HZBaseAdapter *)adapter {
    NSLog(@"HeyzapMediation: ad shown from %@",[adapter name]);
    [self sendNetworkCallback: HZNetworkCallbackShow forNetwork: [adapter name]];
    
    HZMediationCurrentShownAd *currentAd = self.currentShownAd;
    
    [currentAd.eventReporter reportImpressionForAdapter:adapter];
    [self.segmentationController recordImpressionWithCreativeType:currentAd.eventReporter.creativeType tag:currentAd.tag adapter:adapter];
    
    
    // Notify dependent objects of a show
    if (currentAd.showOptions.requestingAdType == HZAdTypeInterstitial && currentAd.eventReporter.creativeType == HZCreativeTypeVideo) {
        [self.interstitialVideoManager didShowInterstitialVideo];
    }
    
    if (currentAd.showOptions.completion) {
        currentAd.showOptions.completion(YES, nil);
    }
    
    if (currentAd && currentAd.adState == HZAdStateRequestedShow) {
        self.currentShownAd.adState = HZAdStateShown;
        [[self delegateForAdType:currentAd.showOptions.requestingAdType] didShowAdWithTag:currentAd.tag];
    } else {
        HZELog(@"The network %@ reported that it showed an ad, but we weren't expecting this.",adapter.name);
    }
    
    __weak __typeof(&*currentAd)weakCurrentAd = currentAd;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(adStalenessTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakCurrentAd) {
            HZILog(@"Marking the ad as stale");
            [weakCurrentAd setStale];
        }
    });
}

/**
 *   We do not get this callback from several networks, so we can't rely on it.
 *
 *  @param adapter The adapter showing the ad.
 */
- (void)adapterWasClicked:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackClick forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [self.currentShownAd.eventReporter reportClickForAdapter:adapter];
        [[self delegateForAdType:self.currentShownAd.showOptions.requestingAdType] didClickAdWithTag:self.currentShownAd.tag];
    } else {
        HZELog(@"Ad network %@ reported that an ad was clicked, but we weren't expecting this.",adapter.name);
    }
}

- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackDismiss forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.showOptions.requestingAdType] didHideAdWithTag:self.currentShownAd.tag];
        
        const HZAdType previousAdType = self.currentShownAd.showOptions.requestingAdType;
        NSString *const tag = self.currentShownAd.tag;
        self.currentShownAd = nil;
        [self autoFetchAdType:previousAdType tag:tag];
    } else {
        HZELog(@"Ad network %@ reported that an ad was closed, but we weren't expecting this.",adapter.name);
    }
}

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackAudioStarting forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.showOptions.requestingAdType] willStartAudio];
    } else {
        HZELog(@"Ad network %@ reported that an ad played audio, but we weren't expecting this.",adapter.name);
    }
}

- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackAudioFinished forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.showOptions.requestingAdType] didFinishAudio];
    } else {
        HZELog(@"Ad network %@ reported that an ad finished playing audio, but we weren't expecting this.",adapter.name);
    }
}

- (void)adapterDidFailToShowAd:(HZBaseAdapter *)adapter error:(NSError *)underlyingError {
    
    if (self.currentShownAd) {
        [self sendShowFailureMessagesWithShowOptions:self.currentShownAd.showOptions
                                              error:underlyingError];
        self.currentShownAd = nil;
    } else {
        HZELog(@"Ad network %@ reported that an ad failed to show, but we weren't expecting this.",adapter.name);
    }
}

#pragma mark - Adapter Callbacks (Incentivized)

// Issue: some networks tell you the user completed an incentivized ad only after a network request, potentially after the user has dismissed the ad (I think AppLovin does this).
- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackIncentivizedResultComplete forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self settings] incentivizedAdShown];
        [[self delegateForAdType:self.currentShownAd.showOptions.requestingAdType] didCompleteAdWithTag:self.currentShownAd.tag];
        [self.currentShownAd.eventReporter reportIncentivizedResult:YES forAdapter:adapter incentivizedInfo:self.currentShownAd.showOptions.incentivizedInfo];
    } else {
        HZELog(@"Ad network %@ reported that an incentivized ad was completed, but we weren't expecting this.",adapter.name);
    }
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackIncentivizedResultIncomplete forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self delegateForAdType:HZAdTypeIncentivized] didFailToCompleteAdWithTag:self.currentShownAd.tag];
        [self.currentShownAd.eventReporter reportIncentivizedResult:NO forAdapter:adapter incentivizedInfo:self.currentShownAd.showOptions.incentivizedInfo];
    } else {
        HZELog(@"Ad network %@ reported that an incentivized ad wasn't completed, but we weren't expecting this.",adapter.name);
    }
}


#pragma mark - Banner Mediation

- (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAdapter *adapter))completion {
    HZParameterAssert(options);
    HZParameterAssert(completion);
    
    // People are likely to call fetch immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        HZILog(@"Mediation requestBanner called before mediation started. Will retry.");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestBannerWithOptions:options completion:completion];
        });
        return;
    }
    
    // pre-show error checks
    NSError *preShowError = [self checkForPreShowError:options.tag adType:HZAdTypeBanner];
    if (preShowError) {
        completion(preShowError, nil);
        return;
    }
    
    HZILog(@"Mediation requesting banner for tag: %@ timeout: %f", options.tag, options.fetchTimeout)
    
    dispatch_async(self.fetchQueue, ^{ // necessary for the hzWaitUntilInterval below
        
        // This waits for /mediate to prevent a banner failure because of a slow network req.
        // TODO add metric here
        __block NSDictionary *latestMediate;
        __block NSDictionary *latestMediateParams;
        const BOOL withinTimeout = hzWaitUntilInterval(0.5, ^BOOL{
            latestMediate = self.mediateRequester.latestMediate;
            latestMediateParams = self.mediateRequester.latestMediateParams;
            return latestMediate && latestMediateParams;
        }, 4);
        if (!withinTimeout) {
            // TODO add metric here
            NSError *timeoutError = [[self class] bannerErrorWithDescription:@"Couldn't get /mediate waterfall from Heyzap in time to show a banner ad." underlyingError:nil];
            HZELog(@"Banner fetch error: %@", timeoutError);
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(timeoutError, nil);
            });
            return;
        }
        
        // get the list of adapters to fetch from
        NSOrderedSet *adaptersWithScores = ({
            NSSet *validAdapterClasses = [HeyzapMediation availableAdapters];
            if (options.networkName) {
                validAdapterClasses = [validAdapterClasses objectsPassingTest:^BOOL(Class klass, BOOL *stop) {
                    return [[klass name] isEqualToString:options.networkName];
                }];
            }
            
            NSOrderedSet *currentList = [self.availabilityChecker parseMediateIntoAdaptersForShow:latestMediate validAdapterClasses:validAdapterClasses adType:HZAdTypeBanner];
            
            // Remove adapters that segmentation will not allow to show an ad right now so we don't bother initializing them
            currentList = hzFilterOrderedSet(currentList, ^BOOL(HZMediationAdapterWithCreativeTypeScore *adapterWithScore) {
                if ([self.segmentationController allowAdapter:[adapterWithScore adapter] toShowAdForCreativeType:HZCreativeTypeBanner tag:options.tag]) {
                    return YES;
                } else {
                    HZDLog(@"Ad network %@ not allowed to show a banner ad under current segmentation rules.", [[adapterWithScore adapter] name]);
                    return NO;
                }
            });
            
            // setup all banner adapters that pass segmentation
            for(HZMediationAdapterWithCreativeTypeScore *adapterWithScore in currentList) {
                [self setupAdapterNamed:[[adapterWithScore adapter] name]];
            }
            
            // filter out adapter classes that didn't get set up properly above, since we passed all present adapter classes to `parseMediateIntoAdaptersForShow`
            currentList = hzFilterOrderedSet(currentList, ^BOOL(HZMediationAdapterWithCreativeTypeScore *adapterWithScore) {
                return [self.setupMediatorClasses containsObject:[[adapterWithScore adapter] class]];
            });
            
            currentList;
        });
        
        if ([adaptersWithScores count] == 0) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion([[self class] bannerErrorWithDescription:@"No banner adapters were available to show an ad. Either you do not have any banner networks integrated and set up properly, or your segmentation settings are preventing the network(s) from showing ads right now." underlyingError:nil], nil);
            });
            return;
        }
        
        NSError *eventReporterError;
        HZMediationEventReporter *eventReporter = [[HZMediationEventReporter alloc] initWithJSON:latestMediate
                                                                                   mediateParams:latestMediateParams
                                                                               potentialAdapters:hzMapOrderedSet(adaptersWithScores, ^HZBaseAdapter *(HZMediationAdapterWithCreativeTypeScore * adapterWithScore){return [adapterWithScore adapter];})
                                                                                          adType:HZAdTypeBanner
                                                                                    creativeType:HZCreativeTypeBanner
                                                                                             tag:options.tag
                                                                                           error:&eventReporterError];
        
        if (eventReporterError || !eventReporter) {
            NSError *mediationError = [[self class] bannerErrorWithDescription:@"Couldn't create HZMediationEventReporter" underlyingError:eventReporterError];
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(mediationError, nil);
            });
            
            return;
        }
        
        [self fetchAndShowBannerWithAdapters:adaptersWithScores options:options completion:completion eventReporter:eventReporter latestMediate:latestMediate];
    });
}


const NSTimeInterval bannerTimeout = 20; // max time to wait for all banner adapters to fetch or error out before showing one
const NSTimeInterval bannerPollInterval = 1; // how long to wait between isAvailable calls during the above time window

/**
 *  This method will fetch a banner from each adapter in the given ordered set of HZMediationAdapterWithCreativeTypeScore objects, giving them `bannerTimeout` seconds to fetch. It will continue doing this until at least one adapter fetches successfully, at which point the given completion block will be called.
 *  The only failure case is when the user-set timeout (options.fetchTimeout) expires.
 *
 *  Requirements: The caller should verify that all of the passed parameters are non-nil & the adapter set is not empty.
 */
- (void) fetchAndShowBannerWithAdapters:(NSOrderedSet *)adaptersWithScores options:(HZBannerAdOptions *)options completion:(void (^)(NSError * error, HZBannerAdapter *adapter))completion eventReporter:(HZMediationEventReporter *)eventReporter latestMediate:(NSDictionary *)latestMediate{
    HZParameterAssert(adaptersWithScores);
    HZParameterAssert(options);
    HZParameterAssert(completion);
    HZParameterAssert(eventReporter);
    
    HZILog(@"Mediation attempting to fetch and show a banner with adapters: [%@], tag: %@, timeout: %f", hzMapOrderedSet(adaptersWithScores, ^NSString *(HZMediationAdapterWithCreativeTypeScore *adapterWithScore){ return [[adapterWithScore adapter] name]; }), options.tag, options.fetchTimeout);
    
    dispatch_async(self.fetchQueue, ^{
        NSDate * startDate = [NSDate date];
        __block BOOL succeeded = NO;
        
        __block NSTimeInterval retryInterval = 1;
        NSTimeInterval const maxRetryInterval = 180; // 3 minutes
        
        // below, we'll continue fetching and waiting indefinitely until we succeed, or hit the timeout.
        // this will allow network requests to fail while the SDKs fetch without making devs call fetch again and again and handle failures
        do {
            NSMutableSet *adaptersWithAvailableAds = [[NSMutableSet alloc] init]; // unordered since they will become available asynchronously. order of adaptersWithScores is maintained & used later.
            
            // Fetch all eligible adapters
            dispatch_sync(dispatch_get_main_queue(), ^{
                for (HZMediationAdapterWithCreativeTypeScore *adapterWithScore in adaptersWithScores) {
                    HZDLog(@"Fetching a banner from %@", [[adapterWithScore adapter] name]);
                    adapterWithScore.bannerAdapter = [[adapterWithScore adapter] fetchBannerWithOptions:options reportingDelegate:self];
                }
            });
            
            // Check every so often to see if they all succeeded/failed yet
            __block NSSet *adaptersStillFetching;
            hzWaitUntilInterval(bannerPollInterval, ^BOOL{
                adaptersStillFetching = [hzFilterOrderedSet(adaptersWithScores, ^BOOL(HZMediationAdapterWithCreativeTypeScore *adapterWithScore) {
                    if ([adapterWithScore.bannerAdapter isAvailable]) {
                        [adaptersWithAvailableAds addObject:adapterWithScore];
                        
                        if ([[adapterWithScore bannerAdapter] class] == [HZHeyzapExchangeBannerAdapter class]) {
                            // update Heyzap Exchange's score with latest fetched ad score (ads have their own scores in the exchange, the score currently on the adapter is the per network score all networks have)
                            HZHeyzapExchangeBannerAdapter * exchangeBannerAdapter = (HZHeyzapExchangeBannerAdapter *)adapterWithScore.bannerAdapter;
                            [adapterWithScore.adapter setLatestMediationScore:exchangeBannerAdapter.adScore forCreativeType:HZCreativeTypeBanner];
                        }
                        return NO;
                    }
                    
                    if ([adapterWithScore.bannerAdapter lastError]) {
                        return NO;
                    }
                    
                    // hasn't errored, not available yet, so we're still waiting for this adapter
                    return YES;
                }) set];
                
                return ([adaptersStillFetching count] == 0);
            }, bannerTimeout);
            
            if ([adaptersStillFetching count]) {
                // TODO add a metric here
                HZELog(@"Waited %i seconds, and the following adapter(s) never succeeded or failed to fetch a banner ad: [%@]", (int)bannerTimeout, [hzMap([adaptersStillFetching allObjects], ^NSString *(HZMediationAdapterWithCreativeTypeScore *adapterWithScore) {return [[adapterWithScore adapter] name];}) componentsJoinedByString:@", "]);
            }
            
            if ([adaptersWithAvailableAds count] == 0) {
                retryInterval = MIN((options.fetchTimeout - [[NSDate date] timeIntervalSinceDate:startDate]), retryInterval); // don't wait longer than the user-set timeout would allow
                HZELog(@"None of the available banner adapters were able to fetch an ad [%@]. Retrying in %i seconds...", [hzMap([adaptersWithScores array], ^NSString *(HZMediationAdapterWithCreativeTypeScore *adapterWithScore) {return [[adapterWithScore adapter] name];}) componentsJoinedByString:@", "], (int)retryInterval);
                
                
                [NSThread sleepForTimeInterval:retryInterval];
                retryInterval = MIN(retryInterval * 2, maxRetryInterval);
                
                continue; // try while loop again after sleeping
            }
            
            // adaptersWithScores is in the /mediate order we want to keep. Only leave the HZMediationAdapterWithCreativeTypeScore instances in adaptersWithScores that have available ads
            NSMutableOrderedSet *finalAdapters = [adaptersWithScores mutableCopy];
            [finalAdapters intersectSet:adaptersWithAvailableAds];
            
            // Sort based on score (special case for heyzap exchange's score already handled earlier)
            [self sortAdaptersByScore:finalAdapters ifLatestMediateRequires:latestMediate];
            
            // Show the winner
            HZBannerAdapter *finalAdapter = [[finalAdapters objectAtIndex:0] bannerAdapter];
            finalAdapter.eventReporter = eventReporter;
            [eventReporter reportFetchWithSuccessfulAdapter:finalAdapter.parentAdapter];
            [self.mediateRequester refreshMediate];
            
            HZILog(@"Mediation successfully fetched a banner from %@ for tag: %@ after %f seconds", [[[finalAdapter parentAdapter] class] humanizedName], options.tag, [[NSDate date] timeIntervalSinceDate:startDate]);
            dispatch_sync(dispatch_get_main_queue(), ^{
                // TODO add a metric for the time/number of retries it took to succeed since the initial request by the dev?
                completion(nil, finalAdapter);
            });
            
            succeeded = YES;
            break; // exit while loop
        } while ([[NSDate date] timeIntervalSinceDate:startDate] < options.fetchTimeout);
        
        if (!succeeded) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSError *timeoutError = [HeyzapMediation bannerErrorWithDescription:[NSString stringWithFormat:@"No banners were fetched before the retry timeout (%f seconds) was reached.", options.fetchTimeout] underlyingError:nil];
                [eventReporter reportFetchWithSuccessfulAdapter:nil];
                completion(timeoutError, nil);
            });
        }
    });
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

- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter hadInitialImpressionWithEventReporter:(HZMediationEventReporter *)eventReporter {
    [eventReporter reportImpressionForAdapter:bannerAdapter.parentAdapter];
    [self.segmentationController recordImpressionWithCreativeType:HZCreativeTypeBanner tag:eventReporter.tag adapter:bannerAdapter.parentAdapter];
}

- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter hadReloadedImpressionWithEventReporter:(HZMediationEventReporter *)eventReporter {
    [eventReporter reportImpressionForAdapter:bannerAdapter.parentAdapter];
}

- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter wasClickedWithEventReporter:(HZMediationEventReporter *)eventReporter {
    [eventReporter reportClickForAdapter:bannerAdapter.parentAdapter];
}


#pragma mark - Misc Utility Methods for Adapter Availability

+ (NSString *)commaSeparatedAdapterList
{
    NSMutableArray *adapterNames = [NSMutableArray array];
    for (Class adapterClass in [HeyzapMediation availableAdapters]) {
        [adapterNames addObject:[adapterClass name]];
    }
    return [adapterNames componentsJoinedByString:@","];
}

+ (NSSet *) availableAdapters {
    // Profiling showed this to take > 1 ms; it's doing a decent amount of work checking if all the classes exist.
    static NSSet *availableAdapters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availableAdapters = [[HZBaseAdapter allAdapterClasses] objectsPassingTest: ^BOOL(Class adapter, BOOL *stop){
            return [adapter isSDKAvailable];
        }];
    });
    return availableAdapters;
}

static BOOL forceOnlyHeyzapSDK = NO;
+ (void)forceOnlyHeyzapSDK {
    forceOnlyHeyzapSDK = YES;
}

- (BOOL)isOnlyHeyzapSDK
{
    static BOOL isOnlyHeyzap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isOnlyHeyzap = [[self availableAdaptersWithHeyzap:NO] count] == 0 || forceOnlyHeyzapSDK;
    });
    return isOnlyHeyzap;
}

- (NSSet *)availableAdaptersWithHeyzap:(BOOL)includeHeyzap
{
    return [[HeyzapMediation availableAdapters] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class adapterClass, NSDictionary *bindings) {
        return (includeHeyzap || ![adapterClass isHeyzapAdapter]);
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

- (id)underlyingDelegateForAdType:(HZAdType)adType {
    switch (adType) {
        case HZAdTypeInterstitial: {
            return self.interstitialDelegateProxy.forwardingTarget;
            break;
        }
        case HZAdTypeIncentivized: {
            return self.incentivizedDelegateProxy.forwardingTarget;
            break;
        }
        case HZAdTypeVideo: {
            return self.videoDelegateProxy.forwardingTarget;
            break;
        }
        case HZAdTypeBanner: {
            // Banners use a different delegate system.
            return nil;
        }
    }
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


# pragma mark - Checking Adapter Status

- (BOOL) isNetworkInitialized:(NSString *)network {
    if (network == nil) {
        return NO;
    }
    
    return [self isNetworkClassInitialized:[HZBaseAdapter adapterClassForName:[network lowercaseString]]];
}

- (BOOL) isNetworkClassInitialized:(Class)networkClass {
    for(Class klass in self.setupMediatorClasses) {
        if (klass == networkClass) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) isAdapterInitialized:(HZBaseAdapter *)adapter {
    return [self.setupMediators containsObject:adapter];
}


- (BOOL)isNetworkEnabledByPersistentConfig:(NSString *)network {
    return [self.persistentConfig isNetworkEnabled:network];
}


# pragma mark - Network Callback Management

- (void) setNetworkCallbackBlock: (void (^)(NSString *network, NSString *callback))block {
    _networkCallbackBlock = block;
}

- (void) sendNetworkCallback: (NSString *) callback forNetwork: (NSString *) network {
    if (_networkCallbackBlock != nil) {
        _networkCallbackBlock(network, callback);
    }
}


#pragma mark - Setup Adapters

/**
 *  Setups an adapter
 *
 *  @param adapterName The canonical identifier for the network to be setup.
 *
 *  @return Whether or not the setup was successful
 *
 *  @warning This method *must* be called on a non-main thread. It will block, potentially indefinitely, if the developer never `resumesExpensiveWork`.
 */
- (BOOL)setupAdapterNamed:(NSString *)adapterName {
    HZParameterAssert([NSThread isMainThread] == NO);
    HZParameterAssert(adapterName);
    
    __block BOOL success;
    
    dispatch_sync(self.pausableMainQueue, ^{
        Class adapterClass = [HZBaseAdapter adapterClassForName:adapterName];
        if (!adapterClass) {
            HZELog(@"Unrecognized mediator %@",adapterName);
            success = NO;
        }
        
        if ([self.setupMediatorClasses containsObject:adapterClass]) {
            success = YES;
        } else if ([self.erroredMediatiorClasses containsObject:adapterClass]
                   || ![adapterClass isSDKAvailable]) {
            success = NO;
        } else if (forceOnlyHeyzapSDK && ![adapterClass isHeyzapAdapter]) {
            success = NO;
        } else {
            NSError *credentialError = [[adapterClass sharedAdapter] initializeSDK];
            if (credentialError){
                HZELog(@"Failed to initialize network %@, had error: %@",[adapterClass humanizedName], credentialError);
                self.erroredMediatiorClasses = [self.erroredMediatiorClasses setByAddingObject:adapterClass];
            } else {
                HZILog(@"Setup adapter: %@",[adapterClass humanizedName]);
                HZBaseAdapter *adapter = [adapterClass sharedAdapter];
                adapter.delegate = self;
                self.setupMediators = [self.setupMediators setByAddingObject:adapter];
                self.setupMediatorClasses = [self.setupMediatorClasses setByAddingObject:adapterClass];
                
                [self sendNetworkCallback:HZNetworkCallbackInitialized forNetwork:adapterName];
            }
            success = credentialError == nil;
        }
    });
    
    return success;
}

- (void)setupAllAdapters:(void(^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (Class class in [HZBaseAdapter allAdapterClasses]) {
            [self setupAdapterNamed:[class name]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) { completion(); }
        });
    });
}


#pragma mark - Handling /mediate

/**
 *  Called when /mediate returns with new data
 */
- (void)requesterUpdatedMediate {
    NSDictionary *json = self.mediateRequester.latestMediate;
    _mediationId = [HZDictionaryUtils objectForKey:@"id" ofClass:[NSString class] default:@"" dict:json];
    
    if (!self.interstitialVideoManager) {
        self.interstitialVideoManager = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:json];
    } else {
        [self.interstitialVideoManager updateWithDictionary:json];
    }
    
    if (!self.availabilityChecker) {
        self.availabilityChecker = [[HZMediationAvailabilityChecker alloc] initWithInterstitialVideoManager:self.interstitialVideoManager persistentConfig:self.persistentConfig];
    }
    
    [self updateMediationScoresWithDict:json];
}

- (void)updateMediationScoresWithDict:(NSDictionary *)dict {
    // update scores for every network
    NSError *error;
    NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:dict error:&error];
    
    if(!error){
        for (NSDictionary *network in networks) {
            NSString *networkName = network[@"network"];
            NSSet *creativeTypes = [NSSet setWithArray:network[@"creative_types"]];
            Class adapter = [HZBaseAdapter adapterClassForName:networkName];
            HZBaseAdapter *adapterInstance = [adapter sharedAdapter];
            
            for(NSString * creativeType in creativeTypes) {
                [adapterInstance setLatestMediationScore:network[@"score"] forCreativeType:hzCreativeTypeFromString(creativeType)];
            }
        }
    }
}


#pragma mark - Other

- (void)showTestActivity {
    // People are likely to show the test activity immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showTestActivity];
        });
    } else {
        [self setupAllAdapters:^{
            [HZTestActivityViewController show];
        }];
    }
}

/**
 *  Used to disable Segmentation for the mediation test activity
 */
- (void)enableSegmentation:(BOOL)enabled {
    [self.segmentationController setEnabled:enabled];
}

/**
 *  Lookup the forced network (the test activity calls this)
 *
 *  @param additionalParams Params containing a "network" key
 *
 *  @return The network, if one was looked up.
 */
+ (Class)optionalForcedNetwork:(NSDictionary *)additionalParams {
    NSString *const forcedNetworkName = additionalParams[@"network"];
    return [HZBaseAdapter adapterClassForName:forcedNetworkName];
}


@end