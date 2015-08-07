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

// Event Reporting
#import "HZMediationEventReporter.h"

// Metrics
#import "HZMediationConstants.h"
#import "HZDevice.h"

#import "HZiAdBannerAdapter.h"
#import "HZiAdAdapter.h"
#import "HZBannerAdOptions_Private.h"
#import "HZMediationStarter.h"
#import "HZMediationCurrentShownAd.h"
#import "HZMediateRequester.h"
#import "HZMediationLoadManager.h"
#import "HZMediationAvailabilityChecker.h"

#import "HZTestActivityViewController.h"

#import "HZHeyzapExchangeAdapter.h"
#import "HZHeyzapExchangeBannerAdapter.h"
#import "HZCachingService.h"
#import "HZInterstitialVideoConfig.h"

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

@property (nonatomic) HZMediationStartStatus startStatus;
@property (nonatomic) BOOL hasLoadedFromCache;

// State
@property (nonatomic) HZMediationCurrentShownAd *currentShownAd;


- (void)sendShowFailureMessagesForAdType:(HZAdType)adType options:(HZShowOptions *)options error:(NSError *)underlyingError;

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
        _cachingService = [[HZCachingService alloc] init];
        _starter = [[HZMediationStarter alloc] initWithStartingDelegate:self cachingService:_cachingService];
        _mediateRequester = [[HZMediateRequester alloc] initWithDelegate:self cachingService:_cachingService];
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


- (void)startWithDictionary:(NSDictionary *)dictionary fromCache:(BOOL)fromCache {
    self.settings = [[HZMediationSettings alloc] init];
    [[self settings] setupWithDict:dictionary fromCache:fromCache];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        self.loadManager = [[HZMediationLoadManager alloc] initWithLoadData:dictionary[@"loader"] delegate:self error:&error];
        if (error) {
            HZELog(@"Error initializing network preloader. Mediation won't be possible. %@",error);
        } else {
            self.startStatus = HZMediationStartStatusSuccess;
            [self autoFetchAdType:HZAdTypeInterstitial];
        }
        
    });
}

- (void)fetchForAdType:(HZAdType)adType additionalParams:(NSDictionary *)additionalParams completion:(void (^)(BOOL result, NSError *error))completion
{
    // People are likely to call fetch immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fetchForAdType:adType additionalParams:additionalParams completion:completion];
        });
        return;
    }
    
    HZParameterAssert(self.loadManager);
    HZShowOptions *options = [HZShowOptions new];
    options.completion = completion;
    
    if(adType == HZAdTypeIncentivized && ![[self settings] shouldAllowIncentivizedAd]) {
        [[self delegateForAdType:adType] didFailToReceiveAdWithTag:options.tag];
        if(completion) {
            completion(NO, [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"This user has reached their daily limit for incentivized ad views."}]);
        }
        return;
    }
    
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:additionalParams];
    
    [self.loadManager fetchAdType:adType showOptions:options optionalForcedNetwork:optionalForcedNetwork];
}

- (void)autoFetchAdType:(HZAdType)adType {
    if (![[HZAdsManager sharedManager] isOptionEnabled: HZAdOptionsDisableAutoPrefetching]) {
        [self fetchForAdType:adType additionalParams:nil completion:^(BOOL result, NSError *error) {
            if(adType == HZAdTypeIncentivized && ![[self settings] shouldAllowIncentivizedAd]) {
                // don't keep autofetching if it'll keep failing because of the daily limit
                return;
            }
            
            if (error) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self autoFetchAdType:adType];
                });
            }
        }];
    }
}

// Dictionary keys
NSString * const kHZAdapterKey = @"name";
NSString * const kHZDataKey = @"data";

#pragma mark - Ads

- (void)showAdForAdUnitType:(HZAdType)adType additionalParams:(NSDictionary *)additionalParams options:(HZShowOptions *)options
{
    
    NSError *preShowError = [self checkForPreShowError:options.tag adType:adType];
    if (preShowError) {
        [self sendShowFailureMessagesForAdType:adType options:options error:preShowError];
        return;
    }
    
    // Getting /mediate and sending failure message can be part of the
    // TODO: tell the server if an outdated or cached mediate is being used. Potentially include the outdated time diff.
    NSDictionary *const latestMediate = [self.mediateRequester latestMediate];
    NSDictionary *const latestMediateParams = [self.mediateRequester latestMediateParams];
    if (!latestMediate || !latestMediateParams) {
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Didn't get the waterfall from Heyzap's servers before a request to show an ad was made."}];
        [self sendShowFailureMessagesForAdType:adType options:options error:error];
        return;
    }
    
    NSError *eventReporterError;
    
    NSMutableOrderedSet *adapters = [[self.availabilityChecker parseMediateIntoAdapters:latestMediate setupAdapterClasses:self.setupMediatorClasses adType:adType] mutableCopy];
    
    // update Heyzap Exchange's scores with latest fetched ad scores (ads have their own scores in the exchange, the currently stored score is per network)
    [[HZHeyzapExchangeAdapter sharedInstance] setAllMediationScoresForReadyAds];
    
    /*  Sort the adapters, largest score first
     *
     *  TODO: Problem: we only sort here based on the requested adType's score.
     *  To fully support interstitial video (blended) for the exchange, we could split this method into two parts:
     *
     *      1. decide if we're using video or interstitial (static)
     *      2. use that adType that we decided on in #1 for the rest of the method instead of the requested adType (including in the sort & for the show call)
     *
     *  This way, we'd know which adType to compare the networks on in the sort, and the show call would be told to show the correct adType.
     *  Right now, we are storing the mediationScore for video-only networks in both HZAdTypeInterstitial and HZAdTypeVideo to partially get around this,
     *  but this still doesn't allow the exchange to participate in blended interstitials.
     */
    [self sortAdaptersByScore:adapters ifLatestMediateRequires:latestMediate forAdType:adType];
    
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:additionalParams];
    
    HZBaseAdapter *chosenAdapter = [self.availabilityChecker firstAdapterWithAdForAdType:adType adapters:adapters optionalForcedNetwork:optionalForcedNetwork];
    
    /// Start event reporting
    HZMediationEventReporter *eventReporter = [[HZMediationEventReporter alloc] initWithJSON:latestMediate mediateParams:latestMediateParams potentialAdapters:adapters adType:adType tag:options.tag error:&eventReporterError];
    
    if (eventReporterError) {
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{
                                                                                       NSLocalizedDescriptionKey: @"Failed to parse /mediate response",
                                                                                       NSUnderlyingErrorKey:eventReporterError,
                                                                                       }];
        [self sendShowFailureMessagesForAdType:adType options:options error:error];
        return;
    }
    
    [eventReporter reportFetchWithSuccessfulAdapter:chosenAdapter];
    if (!chosenAdapter) {
        // TODO: make that error message prettier.
        NSString *const errorMessage = [NSString stringWithFormat:@"No ad network had an ad to show. Ad networks we checked were: %@", adapters];
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        [self sendShowFailureMessagesForAdType:adType options:options error:error];
        return;
    }
    
    self.currentShownAd = [[HZMediationCurrentShownAd alloc] initWithEventReporter:eventReporter adapter:chosenAdapter options:options];
    
    /// Notify dependent objects of a show
    if (adType == HZAdTypeInterstitial && [chosenAdapter isVideoOnlyNetwork]) {
        [self.availabilityChecker didShowInterstitialVideo];
    }
    [self.mediateRequester refreshMediate];
    
    /// Show ad
    [chosenAdapter showAdForType:adType options:options];
}

- (void) sortAdaptersByScore:(NSMutableOrderedSet *)adapters ifLatestMediateRequires:(NSDictionary *)latestMediate forAdType:(HZAdType)adType {
    BOOL shouldSortAdapters = [[HZDictionaryUtils objectForKey:@"sort" ofClass:[NSNumber class] default:@0 dict:latestMediate] boolValue];
    
    if(shouldSortAdapters) {
        [adapters sortUsingComparator:^(HZBaseAdapter *obj1, HZBaseAdapter *obj2) {
            // [obj2 compare:obj1] will sort highest score first
            return [[obj2 latestMediationScoreForAdType:adType] compare:[obj1 latestMediationScoreForAdType:adType]];
        }];
    }
    
    // avoid the loop if we don't want to print the scores
    if([HZLog debugLevel] >= HZDebugLevelVerbose) {
        NSMutableString *scoreStr = [NSMutableString stringWithFormat:@"Waterfall for adType=%@ (%@ order): ", NSStringFromAdType(adType), shouldSortAdapters ? @"Sorted" : @"UNSORTED"];
        for(HZBaseAdapter *adapter in adapters) {
            [scoreStr appendFormat:@"[%@: %@]", [adapter name], shouldSortAdapters ? [adapter latestMediationScoreForAdType:adType] : @"--"];
        }
        
        HZDLog(@"%@",scoreStr);
    }
}

- (NSError *)checkForPreShowError:(NSString *)tag adType:(HZAdType)adType {
    if (self.startStatus != HZMediationStartStatusSuccess) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"SDK hasn't finished starting."}];
    } else if (self.pausableQueueIsPaused) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Attempted to show an ad when the SDK is paused."}];
    } else if ([[[self settings] disabledTags] containsObject:[HZAdModel normalizeTag:tag]]) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Attempted to show an ad with a disabled tag"}];
    } else if (self.currentShownAd) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"An ad is already shown or attempting to be shown"}];
    } else if ([[self settings] IAPAdsTimeOut] && adType != HZAdTypeIncentivized) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Ads are disabled because of a recent in-app-purchase."}];
    } else if(adType == HZAdTypeIncentivized && ![[self settings] shouldAllowIncentivizedAd]) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"This user has reached their daily limit for incentivized ad views."}];
    }
    
    return nil;
}

- (void)sendShowFailureMessagesForAdType:(HZAdType)adType options:(HZShowOptions *)options error:(NSError *)underlyingError {
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
    
    [[self delegateForAdType:adType] didFailToShowAdWithTag:options.tag andError:error];
}

#pragma mark - Querying adapters

- (BOOL)isAvailableForAdUnitType:(const HZAdType)adType tag:(NSString *)tag
{
    tag = [HZAdModel normalizeTag:tag];
    
    return [[self availableAdaptersForAdType:adType tag:tag] count] != 0;
}

- (BOOL)isAvailableForAdUnitType:(const HZAdType)adType tag:(NSString *)tag network:(HZBaseAdapter *const)network {
    tag = [HZAdModel normalizeTag:tag];
    return [[self availableAdaptersForAdType:adType tag:tag] containsObject:network]
    && [[self settings] tagIsEnabled:tag];
}

- (NSOrderedSet *)availableAdaptersForAdType:(const HZAdType)adType tag:(NSString *)tag {
    NSError *preShowError = [self checkForPreShowError:tag adType:adType];
    if (preShowError || !self.mediateRequester.latestMediate) {
        return [NSOrderedSet orderedSet];
    }
    
    NSOrderedSet *const availableAdapters = [self.availabilityChecker availableAdaptersForAdType:adType adapters:[NSOrderedSet orderedSetWithSet:self.setupMediators]];
    
    NSIndexSet *const adapterIndexes = [availableAdapters indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter * adapter, NSUInteger idx, BOOL *stop) {
        return [adapter hasAdForType:adType];
    }];
    
    return [NSOrderedSet orderedSetWithArray:[availableAdapters objectsAtIndexes:adapterIndexes]];
}

#pragma mark - Adapter Callbacks

- (void)adapterDidShowAd:(HZBaseAdapter *)adapter {
    NSLog(@"HeyzapMediation: ad shown from %@",[adapter name]);
    [self sendNetworkCallback: HZNetworkCallbackShow forNetwork: [adapter name]];
    
    HZMediationCurrentShownAd *currentAd = self.currentShownAd;
    
    [currentAd.eventReporter reportImpressionForAdapter:adapter];
    
    if (currentAd && currentAd.adState == HZAdStateRequestedShow) {
        self.currentShownAd.adState = HZAdStateShown;
        [[self delegateForAdType:currentAd.eventReporter.adType] didShowAdWithTag:currentAd.tag];
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
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] didClickAdWithTag:self.currentShownAd.tag];
    }
}

- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackDismiss forNetwork: [adapter name]];
    const HZAdType previousAdType = self.currentShownAd.eventReporter.adType;
    
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] didHideAdWithTag:self.currentShownAd.tag];
    }
    
    self.currentShownAd = nil;
    [self autoFetchAdType:previousAdType];
}

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackAudioStarting forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] willStartAudio];
    }
}

- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackAudioFinished forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] didFinishAudio];
    }
}

- (void)adapterDidFailToShowAd:(HZBaseAdapter *)adapter error:(NSError *)underlyingError {
    
    if (self.currentShownAd) {
        [self sendShowFailureMessagesForAdType:self.currentShownAd.eventReporter.adType
                                       options:self.currentShownAd.showOptions
                                         error:underlyingError];
        self.currentShownAd = nil;
    }
}

#pragma mark - Incentivized Specific

// Issue: some networks tell you the user completed an incentivized ad only after a network request, potentially after the user has dismissed the ad (I think AppLovin does this).
- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackIncentivizedResultComplete forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self settings] incentivizedAdShown];
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] didCompleteAdWithTag:self.currentShownAd.tag];
        [self.currentShownAd.eventReporter reportIncentivizedResult:YES forAdapter:adapter];
    }
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    [self sendNetworkCallback: HZNetworkCallbackIncentivizedResultIncomplete forNetwork: [adapter name]];
    
    if (self.currentShownAd) {
        [[self delegateForAdType:HZAdTypeIncentivized] didFailToCompleteAdWithTag:self.currentShownAd.tag];
        [self.currentShownAd.eventReporter reportIncentivizedResult:NO forAdapter:adapter];
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
    
    if ([[self settings] IAPAdsTimeOut]) {
        HZILog(@"Ads disabled because of an IAP");
        completion([[self class] bannerErrorWithDescription:@"Ads disabled because of an IAP" underlyingError:nil], nil);
        return;
    }
    
    // People are likely to call fetch immediately after calling start, so just re-enqueue their calls.
    // This feels pretty hacky..
    if (self.startStatus == HZMediationStartStatusNotStarted) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestBannerWithOptions:options completion:completion];
        });
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
            NSError *timeoutError = [[self class] bannerErrorWithDescription:@"Couldn't get /mediate waterfall from Heyzap." underlyingError:nil];
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(timeoutError, nil);
            });
            return;
        }
        
        NSError *error;
        NSOrderedSet *const adapterClasses = [self getBannerClasses:latestMediate error:&error];
        if (!adapterClasses) {
            NSError *timeoutError = [[self class] bannerErrorWithDescription:@"Couldn't get adapter classes to use" underlyingError:error];
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(timeoutError, nil);
            });
            return;
        }
        
        for (Class adapterClass in adapterClasses) {
            [self setupAdapterNamed:[adapterClass name]];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            NSOrderedSet *adapters = ({
                NSOrderedSet *a1 = [self.availabilityChecker parseMediateIntoAdapters:latestMediate setupAdapterClasses:self.setupMediatorClasses adType:HZAdTypeBanner];
                NSOrderedSet *a2 = hzFilterOrderedSet(a1, ^BOOL(HZBaseAdapter *adapter) {
                    // This should be factored out into a general way of saying "does the ad network have credentials for X ad format?
                    return [adapter hasBannerCredentials];
                });
                NSOrderedSet *a3 = hzFilterOrderedSet(a2, ^BOOL(HZBaseAdapter *adapter) {
                    if (options.networkName) {
                        return [[adapter name] isEqualToString:options.networkName];
                    } else {
                        return YES;
                    }
                });
                
                a3;
            });
            
            if ([adapters count] == 0) {
                completion([NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"No banner adapters were available"}], nil);
                return;
            }
            
            NSError *eventReporterError;
            HZMediationEventReporter *eventReporter = [[HZMediationEventReporter alloc] initWithJSON:latestMediate mediateParams:latestMediateParams potentialAdapters:adapters adType:HZAdTypeBanner tag:options.tag error:&eventReporterError];
            
            if (eventReporterError) {
                NSError *mediationError = [[self class] bannerErrorWithDescription:@"Couldn't create HZMediationEventReporter" underlyingError:error];
                completion(mediationError, nil);
                return;
            }
            
            NSMutableOrderedSet *adaptersWithAvailableAds = [[NSMutableOrderedSet alloc] init];
            
            dispatch_async(self.fetchQueue, ^{
                __block BOOL heyzapExchangeAvailable = NO;
                __block HZHeyzapExchangeBannerAdapter *heyzapExchangeBannerAdapter;
                
                for (HZBaseAdapter *baseAdapter in adapters) {
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
                        completion([[self class] bannerErrorWithDescription:@"None of the mediated ad networks had a banner available" underlyingError:nil], nil);
                        return;
                    }
                    
                    BOOL shouldSortAdapters = [[HZDictionaryUtils objectForKey:@"sort" ofClass:[NSNumber class] default:@0 dict:latestMediate] boolValue];
                    if(shouldSortAdapters) {
                        // sort adapters with ads by score, also considering RTB score from heyzap exchange fetch
                        if(heyzapExchangeAvailable){
                            [heyzapExchangeBannerAdapter.parentAdapter setLatestMediationScore:heyzapExchangeBannerAdapter.adScore forAdType:HZAdTypeBanner];
                        }
                        
                        [adaptersWithAvailableAds sortUsingComparator:^(HZBannerAdapter *obj1, HZBannerAdapter *obj2) {
                            // [obj2 compare:obj1] will sort highest score first
                            return [[obj2.parentAdapter latestMediationScoreForAdType:HZAdTypeBanner] compare:[obj1.parentAdapter latestMediationScoreForAdType:HZAdTypeBanner]];
                        }];
                    }
                    
                    HZBannerAdapter *finalAdapter = [adaptersWithAvailableAds objectAtIndex:0];
                    finalAdapter.eventReporter = eventReporter;
                    [eventReporter reportFetchWithSuccessfulAdapter:finalAdapter.parentAdapter];
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

- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter hadImpressionWithEventReporter:(HZMediationEventReporter *)eventReporter {
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
        
        NSDictionary *credentials = self.starter.networkNameToCredentials[adapterName];
        
        if ([self.setupMediatorClasses containsObject:adapterClass]) {
            success = YES;
        } else if ([self.erroredMediatiorClasses containsObject:adapterClass]
                   || ![adapterClass isSDKAvailable]
                   || !credentials) {
            success = NO;
        } else if (forceOnlyHeyzapSDK && ![adapterClass isHeyzapAdapter]) {
            success = NO;
        } else {
            NSError *credentialError = [adapterClass enableWithCredentials:credentials];
            if (credentialError){
                HZELog(@"Failed to initialize network %@, had error: %@",[adapterClass humanizedName], credentialError);
                self.erroredMediatiorClasses = [self.erroredMediatiorClasses setByAddingObject:adapterClass];
            } else {
                HZILog(@"Setup adapter: %@",[adapterClass humanizedName]);
                HZBaseAdapter *adapter = [adapterClass sharedInstance];
                adapter.delegate = self;
                self.setupMediators = [self.setupMediators setByAddingObject:adapter];
                self.setupMediatorClasses = [self.setupMediatorClasses setByAddingObject:adapterClass];
            }
            success = credentialError == nil;
        }
    });
    
    return success;
}

- (void)didFetchAdOfType:(HZAdType)adType options:(HZShowOptions *)showOptions {
    [[self delegateForAdType:adType] didReceiveAdWithTag:showOptions.tag];
    if (showOptions.completion) { showOptions.completion(YES, nil); }
}

- (void)didFailToFetchAdOfType:(HZAdType)adType options:(HZShowOptions *)showOptions {
    // TODO: can we improve this error somehow?
    NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil];
    
    [[self delegateForAdType:adType] didFailToReceiveAdWithTag:showOptions.tag];
    if (showOptions.completion) { showOptions.completion(NO, error); }
}

- (NSOrderedSet *)getBannerClasses:(NSDictionary *)json error:(NSError **)error {
    HZParameterAssert(json);
    HZParameterAssert(error);
    
    NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json error:error];
    // Check error macro for networks being nil/empty
    
    if (!networks) {
        return nil;
    }
    
    NSMutableOrderedSet *adapterClasses = [NSMutableOrderedSet orderedSet];
    
    for (NSDictionary *network in networks) {
        NSArray *creativeTypes = [HZDictionaryUtils objectForKey:@"creative_types" ofClass:[NSArray class] default:@[] dict:network];
        if ([creativeTypes containsObject:@"BANNER"]) {
            NSString *networkName = network[@"network"];
            Class adapter = [HZBaseAdapter adapterClassForName:networkName];
            if (adapter && [adapter isSDKAvailable]) { // TODO: check supported ad types
                [adapterClasses addObject:adapter];
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
        self.availabilityChecker = [[HZMediationAvailabilityChecker alloc] initWithInterstitialVideoConfig:interstitialVideoConfig];
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
            HZBaseAdapter *adapterInstance = (HZBaseAdapter *)[adapter sharedInstance];
            
            for(NSString * creativeType in creativeTypes) {
                HZAdType adType = hzAdTypeFromCreativeTypeString(creativeType);
                [adapterInstance setLatestMediationScore:network[@"score"] forAdType:adType];
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

@end