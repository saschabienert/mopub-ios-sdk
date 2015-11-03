//
//  HZBaseAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZBaseAdapter_Internal.h"
#import "HZVungleAdapter.h"
#import "HZChartboostAdapter.h"
#import "HZMediationConstants.h"
#import "HZAdColonyAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZHeyzapAdapter.h"
#import "HZAppLovinAdapter.h"
#import "HZUnityAdsAdapter.h"
#import "HZCrossPromoAdapter.h"
#import "HZFacebookAdapter.h"
#import "HZiAdAdapter.h"
#import "HZBannerAdapter.h"
#import "HZHyprmxAdapter.h"
#import "HZHeyzapExchangeAdapter.h"
#import "HZLeadboltAdapter.h"
#import "HZLog.h"
#import "HZDispatch.h"

@interface HZBaseAdapter()
//key: HZCreativeType value: NSNumber *
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *latestMediationScores;
@property (nonatomic) BOOL isInitialized;
@end

@implementation HZBaseAdapter

#define ABSTRACT_METHOD_ERROR() @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Subclasses should override this method" userInfo:nil];

NSTimeInterval const kHZIsAvailablePollIntervalSecondsDefault = 1;

// When making a new subclass, copy methods in this section into the subclass and implement them, if necessary.
#pragma mark - BEGIN METHODS TO PASTE INTO NEW SUBCLASS

+ (instancetype)sharedAdapter
{
    ABSTRACT_METHOD_ERROR();
}

#pragma mark - Adapter Protocol

- (void)loadCredentials {
    
}

- (NSError *)internalInitializeSDK {
    ABSTRACT_METHOD_ERROR();
}

+ (BOOL)isSDKAvailable
{
    ABSTRACT_METHOD_ERROR();
}

+ (NSString *)name
{
    ABSTRACT_METHOD_ERROR();
}

+ (NSString *)humanizedName {
    ABSTRACT_METHOD_ERROR();
}

+ (NSString *)sdkVersion
{
    ABSTRACT_METHOD_ERROR();
}

- (NSString *)testActivityInstructions {
    return nil;
}

- (HZCreativeType)supportedCreativeTypes
{
    ABSTRACT_METHOD_ERROR();
}

// does not currently check for placement ID overrides... not sure it should - it'd add extra complexity and we don't allow people to skip entering default placement IDs on their dashboards
- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    return YES;
}

- (BOOL) hasNecessaryCredentials {
    return YES;
}

- (void)internalPrefetchAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    ABSTRACT_METHOD_ERROR();
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options
{
    ABSTRACT_METHOD_ERROR();
}

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options placementIDOverride:(nullable NSString *)placementIDOverride reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return nil;
}

#pragma mark - Fetch error storage/reporting

// default implementation only sorts errors based on creativeType. for subclasses that have errors that need to be sorted in a more simple/complex manner (i.e.: via creativeType and placementID for adapters that utilize placementID overrides, or via just one object for adapters that don't support multiple creativeTypes), provide your own implementation
- (NSError *)lastFetchErrorForAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    switch (dataProvider.creativeType) {
        case HZCreativeTypeStatic: {
            return self.lastStaticFetchError;
            break;
        }
        case HZCreativeTypeIncentivized: {
            return self.lastIncentivizedFetchError;
            break;
        }
        case HZCreativeTypeVideo: {
            return self.lastVideoFetchError;
            break;
        }
        case HZCreativeTypeBanner:
        case HZCreativeTypeNative:
        case HZCreativeTypeUnknown: {
            // ignored
            return nil;
        }
    }
    return nil;
}

// default implementation only sorts errors based on creativeType. for subclasses that have errors that need to be sorted in a more simple/complex manner (i.e.: via creativeType and placementID for adapters that utilize placementID overrides, or via just one object for adapters that don't support multiple creativeTypes), provide your own implementation
- (void) setLastFetchError:(NSError *)error forAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    switch(dataProvider.creativeType) {
        case HZCreativeTypeStatic:
            self.lastStaticFetchError = error;
            break;
        case HZCreativeTypeIncentivized:
            self.lastIncentivizedFetchError = error;
            break;
        case HZCreativeTypeVideo:
            self.lastVideoFetchError = error;
            break;
        default://ignore banners, native, etc. here
            break;
    }
}

#pragma mark - Logging


- (void) toggleLogging { }


#pragma mark - END METHODS TO PASTE INTO NEW SUBCLASS

#pragma mark - Instance methods that call class methods

- (NSString *)sdkVersion
{
    return [[self class] sdkVersion];
}

- (NSString *)name
{
    return [[self class] name];
}

- (NSString *)humanizedName
{
    return [[self class] humanizedName];
}

#pragma mark - Public methods that call internal methods

- (NSError *)initializeSDK {
    __block NSError *error;
    hzEnsureMainQueue(^{
        error = [self internalInitializeSDK];
        if (!error && !self.isInitialized) {
            self.isInitialized = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggingChanged:) name:kHZLogThirdPartyLoggingEnabledChangedNotification object:[HZLog class]];
        }
    });
    return error;
}

- (BOOL)hasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    if (dataProvider.creativeType == HZCreativeTypeBanner) {
        HZELog(@"hasAdWithMetadata should not be sent to adapters asking about banner ads.");
        return NO;
    }
    
    if (![self supportsCreativeType:dataProvider.creativeType]) return NO;
    
    __block BOOL hasAd;
    hzEnsureMainQueue(^{
        hasAd = [self internalHasAdWithMetadata:dataProvider];
    });
    return hasAd;
}

- (void)prefetchAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    if(![self supportsCreativeType:dataProvider.creativeType] || dataProvider.creativeType == HZCreativeTypeBanner){
        HZELog(@"HZBaseAdapter: prefetchForCreativeType:%@ called for %@ adapter (%@)", NSStringFromCreativeType(dataProvider.creativeType), [self name], dataProvider.creativeType == HZCreativeTypeBanner ? @"banners can't be fetched via the normal adapter": @"unsupported creativeType");
        return;
    }
    
    hzEnsureMainQueue(^{
        if ([self hasAdWithMetadata:dataProvider]) return;
        
        [self clearLastFetchErrorForAdsWithMatchingMetadata:dataProvider];
        [self internalPrefetchAdWithMetadata:dataProvider];
    });
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options placementIDOverride:(NSString *)placementIDOverride reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    __block HZBannerAdapter *bannerAdapter;
    hzEnsureMainQueue(^{
        bannerAdapter = [self internalFetchBannerWithOptions:options placementIDOverride:placementIDOverride reportingDelegate:reportingDelegate];
    });
    return bannerAdapter;
}

- (void)showAdWithOptions:(HZShowOptions *)options
{
    if (![self supportsCreativeType:options.creativeType] || options.creativeType == HZCreativeTypeBanner) {
        NSError *const error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ adapter was asked to show an unsupported creativeType: %@", [[self class] humanizedName], NSStringFromCreativeType(options.creativeType)]}];
        [self.delegate adapterDidFailToShowAd:self error:error];
        return;
    }
    
    hzEnsureMainQueue(^{
        [self internalShowAdWithOptions:options];
    });
}

#pragma mark - Common, shared logic

- (BOOL)supportsCreativeType:(HZCreativeType)creativeType
{
    return [self supportedCreativeTypes] & creativeType;
}

- (NSNumber *) latestMediationScoreForCreativeType:(HZCreativeType)creativeType {
    if(!self.latestMediationScores){
        self.latestMediationScores = [[NSMutableDictionary alloc] init];
    }
    
    return self.latestMediationScores[@(creativeType)] ?: @0;
}

- (void) setLatestMediationScore:(NSNumber *)score forCreativeType:(HZCreativeType)creativeType {
    if(!self.latestMediationScores){
        self.latestMediationScores = [[NSMutableDictionary alloc]init];
    }
    
    self.latestMediationScores[@(creativeType)] = (score ?: @0);
}

- (void)setCredentials:(NSDictionary *const)credentials {
    if (!_credentials) {
        _credentials = credentials;
        [self loadCredentials];
    }
}

- (HZAdType) possibleSupportedAdTypes {
    HZAdType returnVal = 0;
    HZCreativeType supportedCreativeTypes = [self supportedCreativeTypes];
    if (supportedCreativeTypes & HZCreativeTypeStatic) {
        returnVal |= HZAdTypeInterstitial;
    }
    
    if (supportedCreativeTypes & HZCreativeTypeVideo) {
        returnVal |= (HZAdTypeInterstitial | HZAdTypeVideo); // blended interstitials
    }
    
    if(supportedCreativeTypes & HZCreativeTypeIncentivized) {
        returnVal |= HZAdTypeIncentivized;
    }
    
    if(supportedCreativeTypes & HZCreativeTypeBanner) {
        returnVal |= HZAdTypeBanner;
    }
    
    return returnVal;
}

- (void)clearLastFetchErrorForAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    [self setLastFetchError:nil forAdsWithMatchingMetadata:dataProvider];
}

- (BOOL) isLoggingEnabled {
    return ([HZLog isThirdPartyLoggingEnabled] ? YES : NO);
}

- (void) loggingChanged:(NSNotification *) notification {
    [self toggleLogging];
}

+ (NSTimeInterval)isAvailablePollInterval {
    return kHZIsAvailablePollIntervalSecondsDefault;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Adapter management

+ (Class)adapterClassForName:(NSString *)adapterName
{
    static NSMutableDictionary *nameToClassMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nameToClassMapping = [NSMutableDictionary dictionary];
        for (Class klass in [self allAdapterClasses]) {
            nameToClassMapping[[klass name]] = klass;
        }
    });
    
    return nameToClassMapping[adapterName];
}

+ (NSSet *)allAdapterClasses
{
    return [NSSet setWithObjects:
            [HZVungleAdapter class],
            [HZChartboostAdapter class],
            [HZAdColonyAdapter class],
            [HZAdMobAdapter class],
            [HZHeyzapAdapter class],
            [HZAppLovinAdapter class],
            [HZCrossPromoAdapter class],
            [HZUnityAdsAdapter class],
            [HZCrossPromoAdapter class],
            [HZFacebookAdapter class],
            [HZiAdAdapter class],
            [HZHyprmxAdapter class],
            [HZHeyzapExchangeAdapter class],
            [HZLeadboltAdapter class],
            nil];
}

+ (NSArray *)testActivityAdapters
{
    return [[[self allAdapterClasses] allObjects] sortedArrayUsingComparator:^
        NSComparisonResult(Class klass1, Class klass2) {
        return [[[klass1 sharedAdapter] name] compare:[[klass2 sharedAdapter] name]];
    }];
}

+ (BOOL)isHeyzapAdapter {
    return NO;
}



@end
