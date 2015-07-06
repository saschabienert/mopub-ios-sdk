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

#define kHZMediationCustomPublisherDataKey @"custom_publisher_data"

@interface HeyzapMediation()

@property (nonatomic, strong) NSSet *setupMediators;
@property (nonatomic, strong) NSSet *setupMediatorClasses;
@property (nonatomic, strong) NSSet *erroredMediatiorClasses;

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

// Child objects HeyzapMediation uses to avoid putting everything in this file
@property (nonatomic, strong) HZMediationStarter *starter;
@property (nonatomic, strong) HZMediateRequester *mediateRequester;
@property (nonatomic, strong) HZMediationLoadManager *loadManager;
@property (nonatomic, strong) HZMediationAvailabilityChecker *availabilityChecker;

@property (nonatomic) HZMediationStartStatus startStatus;
@property (nonatomic) BOOL hasLoadedFromCache;

@property (nonatomic) NSSet *disabledTags;

// State
@property (nonatomic) HZMediationCurrentShownAd *currentShownAd;
@property (nonatomic) NSTimeInterval IAPAdDisableTime;

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
        _remoteDataDictionary = [[NSDictionary alloc] init];
        _erroredMediatiorClasses = [NSSet set];
        _interstitialDelegateProxy = [[HZDelegateProxy alloc] init];
        _incentivizedDelegateProxy = [[HZDelegateProxy alloc] init];
        _videoDelegateProxy = [[HZDelegateProxy alloc] init];
        self.fetchQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_CONCURRENT);
        self.sdkStartQueue = dispatch_queue_create("com.heyzap.sdk.mediation", DISPATCH_QUEUE_SERIAL);
        
        self.pausableMainQueue = dispatch_queue_create("com.heyzap.sdk.mediation.pausable_main", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.pausableMainQueue, dispatch_get_main_queue());
        
        self.startStatus = HZMediationStartStatusNotStarted;
        self.starter = [[HZMediationStarter alloc] initWithStartingDelegate:self];
        self.mediateRequester = [[HZMediateRequester alloc] initWithDelegate:self];
        self.disabledTags = [NSSet set];
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


@synthesize adsTimeOut = _adsTimeOut;

-(NSTimeInterval)adsTimeOut {
    if (_adsTimeOut < [NSDate timeIntervalSinceReferenceDate]) {
        _adsTimeOut = 0;
    }
    return _adsTimeOut;
}

-(void)setAdsTimeOut:(NSTimeInterval)adsTimeOut {
    _adsTimeOut = [[NSDate dateWithTimeIntervalSinceNow:adsTimeOut] timeIntervalSinceReferenceDate];
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

NSString * const kHZIAPAdDisableTime = @"iab_ad_disable_time";
- (void)startWithDictionary:(NSDictionary *)dictionary fromCache:(BOOL)fromCache {
    
    self.IAPAdDisableTime = [[HZDictionaryUtils hzObjectForKey:kHZIAPAdDisableTime
                                                      ofClass:[NSString class]
                                                      default:0
                                                     withDict:dictionary] longLongValue] * 60; // in seconds

    self.countryCode = [HZDictionaryUtils hzObjectForKey:@"countryCode"
                                                 ofClass:[NSString class]
                                                 default:@"zz" // Unknown or invalid; the server also uses this.
                                                withDict:dictionary];
    
    NSArray *disabledTags = [HZDictionaryUtils hzObjectForKey:@"disabled_tags" ofClass:[NSArray class] default:@[] withDict:dictionary];
    self.disabledTags = [NSSet setWithArray:disabledTags];
    
    NSString *jsonString = [HZDictionaryUtils hzObjectForKey:kHZMediationCustomPublisherDataKey
                                                     ofClass:[NSString class]
                                                     default: @"{}"
                                                    withDict:dictionary];
    
    // converts string like "{\"test\":\"foo\"}" to dictionary
    if(jsonString == nil) {
        _remoteDataDictionary = @{};
        NSError *error;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:&error];
        _remoteDataDictionary = (error ? @{} : json);
    }
    
    if(!fromCache){
        [[NSNotificationCenter defaultCenter] postNotificationName:HZRemoteDataRefreshedNotification object:nil userInfo:_remoteDataDictionary];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        self.loadManager = [[HZMediationLoadManager alloc] initWithLoadData:dictionary[@"loader"] delegate:self error:&error];
        if (error) {
            HZELog(@"Error initializing network preloader. Mediation won't be possible. %@",error);
        } else {
            self.startStatus = HZMediationStartStatusSuccess;
        }
        
    });
}

- (void)didFailStartRequest {
    self.startStatus = HZMediationStartStatusFailure;
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
    
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:additionalParams];
    
    [self.loadManager fetchAdType:adType showOptions:options optionalForcedNetwork:optionalForcedNetwork];
}

- (void)autoFetchInterstitial
{
    // TODO implement this.
    if (![[HZAdsManager sharedManager] isOptionEnabled: HZAdOptionsDisableAutoPrefetching]) {
        //        HZShowOptions *options = [HZShowOptions new];
        
        
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
    
    NSOrderedSet *adapters = [self.availabilityChecker parseMediateIntoAdapters:latestMediate setupAdapterClasses:self.setupMediatorClasses adType:adType];
    
    Class optionalForcedNetwork = [[self class] optionalForcedNetwork:additionalParams];
    
    HZBaseAdapter *chosenAdapter = [self.availabilityChecker firstAdapterWithAdForAdType:adType adapters:adapters optionalForcedNetwork:optionalForcedNetwork];
    
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
        NSString *const errorMessage = [NSString stringWithFormat:@"No ad network had an ad to show. Ad networks we checked were: %@",adapters];
        NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        [self sendShowFailureMessagesForAdType:adType options:options error:error];
        return;
    }
    
    self.currentShownAd = [[HZMediationCurrentShownAd alloc] initWithEventReporter:eventReporter tag:options.tag adapter:chosenAdapter];
    
    [self haveAdapter:chosenAdapter showAdWithEventReporter:eventReporter options:options];
}

- (NSError *)checkForPreShowError:(NSString *)tag adType:(HZAdType)adType {
    if (self.startStatus != HZMediationStartStatusSuccess) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"SDK hasn't finished starting."}];
    } else if (self.pausableQueueIsPaused) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Attempted to show an ad when the SDK is paused."}];
    } else if ([self.disabledTags containsObject:[HZAdModel normalizeTag:tag]]) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Attempted to show an ad with a disabled tag"}];
    } else if (self.currentShownAd) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"An ad is already shown or attempting to be shown"}];
    } else if (self.adsTimeOut && adType != HZAdTypeIncentivized) {
        return [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Ads are disabled because of a recent in-app-purchase."}];
    }
    
    return nil;
}

- (void)sendShowFailureMessagesForAdType:(HZAdType)adType options:(HZShowOptions *)options error:(NSError *)error {
    HZELog(@"Error showing ad = %@",error);
    [[self delegateForAdType:adType] didFailToShowAdWithTag:options.tag andError:error];
    if (options.completion) { options.completion(NO,error); }
}

unsigned long long const adapterDidShowAdTimeout = 1.5;

- (void)haveAdapter:(HZBaseAdapter *)adapter showAdWithEventReporter:(HZMediationEventReporter *)eventReporter options:(HZShowOptions *)options
{
    if ([adapter isVideoOnlyNetwork] && eventReporter.adType == HZAdTypeInterstitial) {
        self.lastInterstitialVideoShownDate = [NSDate date];
    }
    
    [adapter showAdForType:eventReporter.adType options:options];
    
    // Check if the adapter has responded yet.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(adapterDidShowAdTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self checkIfAdapterShowedAd:adapter showOptions:options];
    });
}


- (void)sendFailureMessagesForAdType:(HZAdType)adType wasAttemptingToShow:(BOOL)tryingToShow underlyingError:(NSError *)underlyingError options:(HZShowOptions *)options
{
    NSDictionary *userInfo = underlyingError ? @{NSUnderlyingErrorKey: underlyingError} : nil;
    NSError *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:userInfo];
    
    [[self delegateForAdType:adType] didFailToReceiveAdWithTag:nil];
    if (options.completion) { options.completion(NO,error); }
    if (tryingToShow) {
        [[self delegateForAdType:adType] didFailToShowAdWithTag:options.tag andError:error];
    }
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
    && [self tagIsEnabled:tag];
}

- (BOOL)tagIsEnabled:(NSString *)tag {
    HZParameterAssert(tag);
    return ![self.disabledTags containsObject:tag];
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
    HZMediationCurrentShownAd *currentAd = self.currentShownAd;
    
    if (currentAd && currentAd.adState == HZAdStateRequestedShow) {
        self.currentShownAd.adState = HZAdStateShown;
        [[self delegateForAdType:currentAd.eventReporter.adType] didShowAdWithTag:currentAd.tag];
    } else {
        HZELog(@"The network %@ reported that it showed an ad, but we weren't expecting this.",adapter.name);
    }
}

- (void)checkIfAdapterShowedAd:(HZBaseAdapter *)adapter showOptions:(HZShowOptions *)showOptions {
    if (self.currentShownAd && self.currentShownAd.adState == HZAdStateRequestedShow) {
        HZMediationEventReporter *reporter = self.currentShownAd.eventReporter;
        NSError *showError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:
                              @{
                                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Adapter %@ was asked to show an ad, but we didn't Heyzap didn't get a callback from that network reporting that it did so within %llu seconds. Assuming it failed and sending a didFail callback",adapter.name, adapterDidShowAdTimeout]}];
        
        // Assume if we haven't shown yet, the show is broken and we should just log an error.
        self.currentShownAd = nil;
        [[self delegateForAdType:reporter.adType] didFailToShowAdWithTag:reporter.tag andError:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{}]];
        if (showOptions.completion) { showOptions.completion(NO,showError); }
    }
}

/**
 *   We do not get this callback from several networks, so we can't rely on it.
 *
 *  @param adapter The adapter showing the ad.
 */
- (void)adapterWasClicked:(HZBaseAdapter *)adapter
{
    if (self.currentShownAd) {
        [self.currentShownAd.eventReporter reportClickForAdapter:adapter];
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] didClickAdWithTag:self.currentShownAd.tag];
    }
}

- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter
{
    self.currentShownAd = nil;
}

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter
{
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] willStartAudio];
    }
}
- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter
{
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] didFinishAudio];
    }
}

#pragma mark - Incentivized Specific

// Issue: some networks tell you the user completed an incentivized ad only after a network request, potentially after the user has dismissed the ad (I think AppLovin does this).
- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    if (self.currentShownAd) {
        [[self delegateForAdType:self.currentShownAd.eventReporter.adType] didCompleteAdWithTag:self.currentShownAd.tag];
    }
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter
{
    if (self.currentShownAd) {
        [[self delegateForAdType:HZAdTypeIncentivized] didFailToCompleteAdWithTag:self.currentShownAd.tag];
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
    
    if (self.adsTimeOut) {
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
            
            
            NSOrderedSet *adapters1 = [self.availabilityChecker parseMediateIntoAdapters:latestMediate setupAdapterClasses:self.setupMediatorClasses adType:HZAdTypeBanner];
            
            // This should be factored out into a general way of saying "does the ad network have credentials for X ad format?
            NSOrderedSet *adapters = hzFilterOrderedSet(adapters1, ^BOOL(HZBaseAdapter *adapter) {
                return [adapter hasBannerCredentials];
            });
            
            NSError *eventReporterError;
            HZMediationEventReporter *eventReporter = [[HZMediationEventReporter alloc] initWithJSON:latestMediate mediateParams:latestMediateParams potentialAdapters:adapters adType:HZAdTypeBanner tag:options.tag error:&eventReporterError];
            
            if (eventReporterError) {
                NSError *mediationError = [[self class] bannerErrorWithDescription:@"Couldn't create HZMediationEventReporter" underlyingError:error];
                completion(mediationError, nil);
                return;
            }
            
            
            dispatch_async(self.fetchQueue, ^{
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
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            
                            
                            bannerAdapter.eventReporter = eventReporter;
                            [eventReporter reportFetchWithSuccessfulAdapter:baseAdapter];
                            completion(nil, bannerAdapter);
                        });
                        
                        break;
                    } else if (baseAdapter == [adapters lastObject]) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [eventReporter reportFetchWithSuccessfulAdapter:nil];
                            completion([[self class] bannerErrorWithDescription:@"None of the mediated ad networks had a banner available" underlyingError:nil], nil);
                        });
                    }
                    
                }
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
        NSArray *creativeTypes = [HZDictionaryUtils hzObjectForKey:@"creative_types" ofClass:[NSArray class] default:@[] withDict:network];
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

- (void)requesterUpdatedMediate {
    NSDictionary *json = self.mediateRequester.latestMediate;
    if (!self.availabilityChecker) {
        self.availabilityChecker = [[HZMediationAvailabilityChecker alloc] initWithMediateResponse:json];
    } else {
        [self.availabilityChecker updateWithMediateResponse:json];
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