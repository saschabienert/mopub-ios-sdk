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
#import "HZInterstitialVideoConfig.h"
#import "HZCachingService.h"
#import "HZInterstitialVideoConfig.h"
#import "HZMediationPersistentConfig.h"

// Exchange
#import "HZHeyzapExchangeAdapter.h"
#import "HZHeyzapExchangeBannerAdapter.h"

// Segmentation
#import "HZImpressionHistory.h"

NSString * const HZMediationDidReceiveAdNotification = @"HZMediationDidReceiveAdNotification";

@interface HeyzapMediation()

@property (nonatomic, strong) NSSet *setupMediators;
@property (nonatomic, strong) NSSet *setupMediatorClasses;
@property (nonatomic, strong) NSSet *erroredMediatiorClasses;

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

// Child objects HeyzapMediation uses to avoid putting everything in this file
@property (nonatomic, strong) HZCachingService *cachingService;
@property (nonatomic, strong) HZMediationStarter *starter;
@property (nonatomic, strong) HZMediateRequester *mediateRequester;
@property (nonatomic, strong) HZMediationLoadManager *loadManager;
@property (nonatomic, strong) HZMediationAvailabilityChecker *availabilityChecker;
@property (nonatomic, strong) HZMediationSettings *settings;
@property (nonatomic, strong) HZSegmentationController *segmentationController;

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
    [[self settings] setupWithDict:dictionary fromCache:fromCache];
    [self addCredentialsToAdapters:dictionary];
    [self.segmentationController setupFromMediationStart:dictionary completion:^void(BOOL successful){
        self.hasSegmentationSetupFinished = YES;
    }];
    
    NSError *error;
    if (!self.loadManager) {
        self.loadManager = [[HZMediationLoadManager alloc] initWithLoadData:dictionary[@"loader"] delegate:self persistentConfig:self.persistentConfig segmentationController:self.segmentationController error:&error];
        if (error || !self.loadManager) {
            HZELog(@"Error initializing network preloader. Mediation won't be possible. %@",error);
        } else {
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fetchWithOptions:fetchOptions];
        });
        return;
    }
    
    HZParameterAssert(self.loadManager);
    
    if(fetchOptions.requestingAdType == HZAdTypeIncentivized && ![[self settings] shouldAllowIncentivizedAd]) {
        [[self delegateForAdType:fetchOptions.requestingAdType] didFailToReceiveAdWithTag:fetchOptions.tag];
        if(fetchOptions.completion) {
            fetchOptions.completion(NO, [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"This user has reached their daily limit for incentivized ad views."}]);
        }
        return;
    }
    
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:fetchOptions.additionalParameters];
    fetchOptions.creativeTypesToFetch = hzCreativeTypesPossibleForAdType(fetchOptions.requestingAdType);
    
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
                return;
            }
            
            if (error) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self autoFetchAdType:adType tag:tag];
                });
            }
        };
        
        [self fetchWithOptions:fetchOptions];
    }
}


#pragma mark - Fetch (LoadManager) callbacks

- (void)didFetchAdOfCreativeType:(HZCreativeType)creativeType withAdapter:(HZBaseAdapter *)adapter options:(HZFetchOptions *)fetchOptions {
    if ([self.settings tagIsEnabled:fetchOptions.tag]) {
        @synchronized(fetchOptions) {
            fetchOptions.creativeTypesFetchesFinished = [fetchOptions.creativeTypesFetchesFinished setByAddingObject:@(creativeType)];
            if (!fetchOptions.alreadyNotifiedDelegateOfSuccess){
                fetchOptions.alreadyNotifiedDelegateOfSuccess = YES;
                [[self delegateForAdType:fetchOptions.requestingAdType] didReceiveAdWithTag:fetchOptions.tag];
                if (fetchOptions.completion) { fetchOptions.completion(YES, nil); }
                [[NSNotificationCenter defaultCenter] postNotificationName:HZMediationDidReceiveAdNotification object:nil];
            }
        }
    } else {
        [self didFailToFetchAdOfCreativeType:creativeType options:fetchOptions];
    }
}

- (void)didFailToFetchAdOfCreativeType:(HZCreativeType)creativeType options:(HZFetchOptions *)fetchOptions {
    @synchronized(fetchOptions) {
        fetchOptions.creativeTypesFetchesFinished = [fetchOptions.creativeTypesFetchesFinished setByAddingObject:@(creativeType)];
        NSMutableSet *creativeTypesLeftToFetch = [fetchOptions.creativeTypesToFetch mutableCopy];
        [creativeTypesLeftToFetch minusSet:fetchOptions.creativeTypesFetchesFinished];
        if ([creativeTypesLeftToFetch count] == 0) {
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
    
    NSError *preShowError = [self checkForPreShowError:options.tag adType:adType];
    if (preShowError) {
        [self sendShowFailureMessagesWithShowOptions:options error:preShowError];
        return;
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
    
    // this returns a set of HZMediationAdapterWithCreativeTypeScore
    NSMutableOrderedSet *adaptersWithScores = [[self.availabilityChecker parseMediateIntoAdaptersForShow:latestMediate setupAdapterClasses:self.setupMediatorClasses adType:adType] mutableCopy];
    
    /*  Sort the adapters, largest score first. The objects in the set obtained above contain their creative type and score.
     *
     */
    [self sortAdaptersByScore:adaptersWithScores ifLatestMediateRequires:latestMediate];
    
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:additionalParams];
    
    HZMediationAdapterWithCreativeTypeScore *chosenAdapterWithScore = [self.availabilityChecker firstAdapterWithAdForTag:options.tag adaptersWithScores:adaptersWithScores optionalForcedNetwork:optionalForcedNetwork segmentationController:self.segmentationController];
    
    /// Start event reporting
    NSError *eventReporterError;
    NSOrderedSet * plainAdapters = hzMapOrderedSet(adaptersWithScores, ^HZBaseAdapter *(HZMediationAdapterWithCreativeTypeScore * adapterWithScore) { return [adapterWithScore adapter]; });
    
    HZMediationEventReporter *eventReporter = [[HZMediationEventReporter alloc] initWithJSON:latestMediate mediateParams:latestMediateParams potentialAdapters:plainAdapters adType:adType creativeType:[chosenAdapterWithScore creativeType] tag:options.tag error:&eventReporterError];
    
    if (eventReporterError) {
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
    
    // Notify dependent objects of a show
    if (adType == HZAdTypeInterstitial && [chosenAdapterWithScore creativeType] == HZCreativeTypeVideo) {
        [self.availabilityChecker didShowInterstitialVideo];
    }
    
    [self.mediateRequester refreshMediate];
    
    // Show ad
    HZDLog(@"HeyzapMediation: %@ adapter will now show an ad of creativeType: %@. Requested adType: %@", [[chosenAdapterWithScore adapter] name], NSStringFromCreativeType([chosenAdapterWithScore creativeType]), NSStringFromAdType(adType));
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
    } else if (self.currentShownAd && !hzCanShowConcurrentlyWithOtherAds(adType)) {
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

- (void)adapterDidShowAd:(HZBaseAdapter *)adapter {
    NSLog(@"HeyzapMediation: ad shown from %@",[adapter name]);
    [self sendNetworkCallback: HZNetworkCallbackShow forNetwork: [adapter name]];
    
    HZMediationCurrentShownAd *currentAd = self.currentShownAd;
    
    [currentAd.eventReporter reportImpressionForAdapter:adapter];
    [self.segmentationController recordImpressionWithCreativeType:currentAd.eventReporter.creativeType tag:currentAd.tag adapter:adapter];
    if (currentAd.showOptions.completion) {
        currentAd.showOptions.completion(YES, nil);
    }
    
    if (currentAd && currentAd.adState == HZAdStateRequestedShow) {
        self.currentShownAd.adState = HZAdStateShown;
        [[self delegateForAdType:currentAd.showOptions.requestingAdType] didShowAdWithTag:currentAd.tag];
    } else {
        HZELog(@"The network %@ reported that it showed an ad, but we weren't expecting this.",adapter.name);
    }
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

#pragma mark - Incentivized Specific

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

#pragma mark - Misc

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
    return [[HeyzapMediation availableAdapters] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class adapterClass, NSDictionary *bindings) {
        return (includeHeyzap || ![adapterClass isHeyzapAdapter]);
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
    
    NSError *preShowError = [self checkForPreShowError:options.tag adType:HZAdTypeBanner];
    if (preShowError) {
        completion(preShowError, nil);
        return;
    }
    
    dispatch_async(self.fetchQueue, ^{
        __block NSDictionary *latestMediate;
        __block NSDictionary *latestMediateParams;
        const BOOL withinTimeout = hzWaitUntilInterval(0.5, ^BOOL{
            latestMediate = self.mediateRequester.latestMediate;
            latestMediateParams = self.mediateRequester.latestMediateParams;
            return latestMediate && latestMediateParams;
        }, 4);
        
        if (!withinTimeout) {
            NSError *timeoutError = [[self class] bannerErrorWithDescription:@"Couldn't get /mediate waterfall from Heyzap in time to show a banner ad." underlyingError:nil];
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(timeoutError, nil);
            });
            return;
        }
        
        NSError *error;
        NSMutableOrderedSet *adapterClasses = [[self getBannerClasses:latestMediate tag:options.tag error:&error] mutableCopy];
        if (!adapterClasses || [adapterClasses count] == 0) {
            NSError *timeoutError = [[self class] bannerErrorWithDescription:@"No banner adapters available to show an ad." underlyingError:error];
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(timeoutError, nil);
            });
            return;
        }
        
        for (Class adapterClass in adapterClasses) {
            [self setupAdapterNamed:[adapterClass name]];
        }
        
        [adapterClasses intersectSet:self.setupMediatorClasses];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSOrderedSet *adaptersWithScores = ({
                NSOrderedSet *a1 = [self.availabilityChecker parseMediateIntoAdaptersForShow:latestMediate setupAdapterClasses:[adapterClasses set] adType:HZAdTypeBanner];
                NSOrderedSet *a2 = hzFilterOrderedSet(a1, ^BOOL(HZMediationAdapterWithCreativeTypeScore *adapterWithScore) {
                    if (options.networkName) {
                        return [[[adapterWithScore adapter] name] isEqualToString:options.networkName];
                    } else {
                        return YES;
                    }
                });
                
                a2;
            });
            
            if ([adaptersWithScores count] == 0) {
                completion([NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"No banner adapters were available"}], nil);
                return;
            }
            
            NSError *eventReporterError;
            HZMediationEventReporter *eventReporter = [[HZMediationEventReporter alloc] initWithJSON:latestMediate mediateParams:latestMediateParams potentialAdapters:hzMapOrderedSet(adaptersWithScores, ^HZBaseAdapter *(HZMediationAdapterWithCreativeTypeScore * adapterWithScore){return [adapterWithScore adapter];}) adType:HZAdTypeBanner creativeType:HZCreativeTypeBanner tag:options.tag error:&eventReporterError];
            
            if (eventReporterError) {
                NSError *mediationError = [[self class] bannerErrorWithDescription:@"Couldn't create HZMediationEventReporter" underlyingError:error];
                completion(mediationError, nil);
                return;
            }
            
            NSMutableOrderedSet *adaptersWithAvailableAds = [[NSMutableOrderedSet alloc] init];
            
            dispatch_async(self.fetchQueue, ^{
                __block BOOL heyzapExchangeAvailable = NO;
                __block HZHeyzapExchangeBannerAdapter *heyzapExchangeBannerAdapter;
                
                for (HZMediationAdapterWithCreativeTypeScore *adapterWithScore in adaptersWithScores) {
                    __block HZBannerAdapter *bannerAdapter;
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        bannerAdapter = [[adapterWithScore adapter] fetchBannerWithOptions:options reportingDelegate:self];
                    });
                    
                    __block BOOL isAvailable = NO;
                    hzWaitUntilInterval(bannerPollInterval, ^BOOL{
                        isAvailable = [bannerAdapter isAvailable];
                        BOOL passedSegmentationTest = YES; // default to YES so that the return statement below only tells the wait block to stop waiting if we actually fail the test below
                        if (isAvailable) {
                            passedSegmentationTest = [self.segmentationController allowBannerAdapter:bannerAdapter toShowAdForTag:options.tag];
                            if (!passedSegmentationTest) {
                                isAvailable = NO;
                                HZDLog(@"Ad network %@ not allowed to show a banner under current segmentation rules.", [[adapterWithScore adapter] name]);
                            }
                        }
                        
                        if (bannerAdapter.lastError) {
                            HZELog(@"Ad Network %@ had an error loading a banner: %@", [[adapterWithScore adapter] name], bannerAdapter.lastError);
                        }
                        return isAvailable || (bannerAdapter.lastError != nil) || !passedSegmentationTest;
                    }, bannerTimeout);
                    
                    if (isAvailable) {
                        [adaptersWithAvailableAds addObject:bannerAdapter];
                        if([bannerAdapter class] == [HZHeyzapExchangeBannerAdapter class]){
                            heyzapExchangeAvailable = YES;
                            heyzapExchangeBannerAdapter = (HZHeyzapExchangeBannerAdapter *)bannerAdapter;
                        }
                    }
                }
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if([adaptersWithAvailableAds count] == 0){
                        [eventReporter reportFetchWithSuccessfulAdapter:nil];
                        completion([[self class] bannerErrorWithDescription:@"None of the mediated ad networks had a banner available that was allowed to show" underlyingError:nil], nil);
                        return;
                    }
                    
                    BOOL shouldSortAdapters = [[HZDictionaryUtils objectForKey:@"sort" ofClass:[NSNumber class] default:@0 dict:latestMediate] boolValue];
                    if(shouldSortAdapters) {
                        // sort adapters with ads by score, also considering RTB score from heyzap exchange fetch
                        if(heyzapExchangeAvailable){
                            [heyzapExchangeBannerAdapter.parentAdapter setLatestMediationScore:heyzapExchangeBannerAdapter.adScore forCreativeType:HZCreativeTypeBanner];
                        }
                        
                        [adaptersWithAvailableAds sortUsingComparator:^(HZBannerAdapter *obj1, HZBannerAdapter *obj2) {
                            // [obj2 compare:obj1] will sort highest score first
                            return [[obj2.parentAdapter latestMediationScoreForCreativeType:HZCreativeTypeBanner] compare:[obj1.parentAdapter latestMediationScoreForCreativeType:HZCreativeTypeBanner]];
                        }];
                    }
                    
                    // avoid the loop if we don't want to print the scores
                    if([HZLog debugLevel] >= HZDebugLevelVerbose) {
                        NSMutableString *scoreStr = [NSMutableString stringWithFormat:@"Banner waterfall (%@ order): ", shouldSortAdapters ? @"Sorted" : @"UNSORTED"];
                        NSNumberFormatter  *formatter = [[NSNumberFormatter alloc] init];
                        [formatter setMaximumFractionDigits:4];
                        [formatter setNumberStyle:NSNumberFormatterScientificStyle];
                        for(HZBannerAdapter *adapter in adaptersWithAvailableAds) {
                            
                            [scoreStr appendFormat:@"[%@ %@]", [adapter.parentAdapter name], [formatter stringFromNumber:[adapter.parentAdapter latestMediationScoreForCreativeType:HZCreativeTypeBanner]]];
                        }
                        
                        HZDLog(@"%@",scoreStr);
                    }
                    
                    HZBannerAdapter *finalAdapter = [adaptersWithAvailableAds objectAtIndex:0];
                    finalAdapter.eventReporter = eventReporter;
                    [eventReporter reportFetchWithSuccessfulAdapter:finalAdapter.parentAdapter];
                    [self.mediateRequester refreshMediate];
                    completion(nil, finalAdapter);
                });
            });
        });
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

// TODO *** need to implement functionality so that the ad loading only counts as an impression after it is added to the screen, which is mildly tricky (best I have so far is an NStimer to check the superview property).

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

- (BOOL)isAdapterInitialized:(HZBaseAdapter *)adapter {
    return [self.setupMediators containsObject:adapter];
}

- (void) setNetworkCallbackBlock: (void (^)(NSString *network, NSString *callback))block {
    _networkCallbackBlock = block;
}

- (void) sendNetworkCallback: (NSString *) callback forNetwork: (NSString *) network {
    if (_networkCallbackBlock != nil) {
        _networkCallbackBlock(network, callback);
    }
}

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

- (NSOrderedSet *)getBannerClasses:(NSDictionary *)json tag:(NSString *)tag error:(NSError **)error {
    HZParameterAssert(json);
    HZParameterAssert(error);
    
    NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json error:error];
    // Check error macro for networks being nil/empty
    
    if (!networks) {
        return nil;
    }
    
    NSMutableOrderedSet *adapterClasses = [NSMutableOrderedSet orderedSet];
    NSSet *const availableAdapters = [HeyzapMediation availableAdaptersWithHeyzap:YES];
    
    for (NSDictionary *network in networks) {
        NSSet *creativeTypes = [NSSet setWithArray:[HZDictionaryUtils objectForKey:@"creative_types" ofClass:[NSArray class] default:@[] dict:network]];
        if (hzCreativeTypeStringSetContainsCreativeType(creativeTypes, HZCreativeTypeBanner)){
            NSString *networkName = network[@"network"];
            Class adapterClass = [HZBaseAdapter adapterClassForName:networkName];
            if (adapterClass
                && [availableAdapters containsObject:adapterClass]
                && [[adapterClass sharedAdapter] supportsCreativeType:HZCreativeTypeBanner]
                && [[adapterClass sharedAdapter] hasCredentialsForCreativeType:HZCreativeTypeBanner]
                && [self.segmentationController allowAdapter:[adapterClass sharedAdapter] toShowAdForCreativeType:HZCreativeTypeBanner tag:tag]
                && [self isNetworkEnabledByPersistentConfig:networkName]) {
                [adapterClasses addObject:adapterClass];
            }
        }
    }
    
    return adapterClasses;
}

/**
 *  Called when /mediate returns with new data
 */
- (void)requesterUpdatedMediate {
    NSDictionary *json = self.mediateRequester.latestMediate;
    _mediationId = [HZDictionaryUtils objectForKey:@"id" ofClass:[NSString class] default:@"" dict:json];
    
    HZInterstitialVideoConfig *const interstitialVideoConfig = [[HZInterstitialVideoConfig alloc] initWithDictionary:json];
    
    if (!self.availabilityChecker) {
        self.availabilityChecker = [[HZMediationAvailabilityChecker alloc] initWithInterstitialVideoConfig:interstitialVideoConfig persistentConfig:self.persistentConfig];
    } else {
        [self.availabilityChecker updateWithInterstitialVideoConfig:interstitialVideoConfig];
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

- (BOOL)isNetworkEnabledByPersistentConfig:(NSString *)network {
    return [self.persistentConfig isNetworkEnabled:network];
}

@end