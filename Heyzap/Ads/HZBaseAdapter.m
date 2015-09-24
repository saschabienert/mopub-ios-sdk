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

@interface HZBaseAdapter()
//key: HZCreativeType value: NSNumber *
@property (nonatomic, strong) NSMutableDictionary *latestMediationScores;
@end

@implementation HZBaseAdapter

#define ABSTRACT_METHOD_ERROR() @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Subclasses should override this method" userInfo:nil];

NSTimeInterval const kHZIsAvailablePollIntervalSecondsDefault = 1;

#pragma mark - Initialization

+ (instancetype)sharedAdapter
{
    ABSTRACT_METHOD_ERROR();
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Adapter Protocol

- (void)loadCredentials {
    
}

- (NSError *)initializeSDK {
    NSError *error = [self internalInitializeSDK];
    if (!error && !self.isInitialized) {
        _isInitialized = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggingChanged:) name:kHZLogThirdPartyLoggingEnabledChangedNotification object:[HZLog class]];
    }
    return error;
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

- (HZCreativeType)supportedCreativeTypes
{
    ABSTRACT_METHOD_ERROR();
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    ABSTRACT_METHOD_ERROR();
}

- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    if (![self supportsCreativeType:creativeType] || creativeType == HZCreativeTypeBanner) {
        NSError *const error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ adapter was asked to show an unsupported creativeType: %@", [[self class] humanizedName], NSStringFromCreativeType(creativeType)]}];
        [self.delegate adapterDidFailToShowAd:self error:error];
        return;
    }
    
    [self internalShowAdForCreativeType:creativeType options:options];
}

- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    ABSTRACT_METHOD_ERROR();
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return nil;
}

#pragma mark - Logging

- (void) loggingChanged:(NSNotification *) notification {
    [self toggleLogging];
}

- (BOOL) isLoggingEnabled {
    return ([HZLog isThirdPartyLoggingEnabled] ? YES : NO);
}

- (void) toggleLogging { }

#pragma mark - Inferred methods

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

- (BOOL)supportsCreativeType:(HZCreativeType)creativeType
{
    return [self supportedCreativeTypes] & creativeType;
}

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    return YES;
}

- (NSError *)lastErrorForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            return self.lastStaticError;
            break;
        }
        case HZCreativeTypeIncentivized: {
            return self.lastIncentivizedError;
            break;
        }
        case HZCreativeTypeVideo: {
            return self.lastVideoError;
            break;
        }
        case HZCreativeTypeBanner:
        case HZCreativeTypeNative:
        case HZCreativeTypeUnknown: {
            // ignored
            return nil;
        }
    }
}

- (void)clearErrorForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            self.lastStaticError = nil;
            break;
        }
        case HZCreativeTypeIncentivized: {
            self.lastIncentivizedError = nil;
            break;
        }
        case HZCreativeTypeVideo: {
            self.lastVideoError = nil;
            break;
        }
        case HZCreativeTypeBanner:
        case HZCreativeTypeNative:
        case HZCreativeTypeUnknown: {
            // ignored for now
            break;
        }
    }
}

#pragma mark - Implemented Methods

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

+ (NSTimeInterval)isAvailablePollInterval {
    return kHZIsAvailablePollIntervalSecondsDefault;
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

@end
