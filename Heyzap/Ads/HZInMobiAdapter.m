//
//  HZInMobiAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/19/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZInMobiAdapter.h"
#import "HZIMSdk.h"
#import "HZBaseAdapter_Internal.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"

#import "HZIMInterstitial.h"
#import "HZIMInterstitialDelegate.h"
#import "HZInMobiBannerAdapter.h"
#import "HZIMRequestStatus.h"
#import "HZDemographics_Private.h"

typedef NSNumber InMobiAdUnitID;

@interface HZInMobiAdapter() <HZIMInterstitialDelegate>

@property (nonatomic, strong) NSString *accountID;

@property (nonatomic, strong) NSDictionary<HZCreativeTypeObject *, InMobiAdUnitID *> *creativeTypeToAdUnitID;

@property (nonatomic, strong) NSMutableDictionary<HZCreativeTypeObject *, HZIMInterstitial *> *adDictionary;
@property (nonatomic) HZIMInterstitial *backupRewardedVideo;

@end

@implementation HZInMobiAdapter

+ (instancetype)sharedAdapter
{
    static HZInMobiAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZInMobiAdapter alloc] init];
        adapter.forwardingDelegate = [HZAdapterDelegate new];
        adapter.forwardingDelegate.adapter = adapter;
    });
    return adapter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _adDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Adapter Protocol

- (void)loadCredentials {
    self.accountID = [HZDictionaryUtils objectForKey:@"account_id"
                                             ofClass:[NSString class]
                                                dict:self.credentials];
    
    NSDictionary *const creativeTypeToKey = @{
                                              @(HZCreativeTypeStatic):@"static_placement_id",
                                              @(HZCreativeTypeVideo):@"video_placement_id",
                                              @(HZCreativeTypeIncentivized):@"rewarded_video_placement_id",
                                              @(HZCreativeTypeBanner):@"banner_placement_id",
                                              };
    
    NSMutableDictionary *const creativeTypeToAdUnitID = [NSMutableDictionary dictionary];
    
    [creativeTypeToKey enumerateKeysAndObjectsUsingBlock:^(HZCreativeTypeObject *  _Nonnull creativeType, NSString *  _Nonnull credentialKey, BOOL * _Nonnull stop) {
        NSString *const credential = [HZDictionaryUtils objectForKey:credentialKey
                                                             ofClass:[NSString class]
                                                                dict:self.credentials];
        if (credential) {
            creativeTypeToAdUnitID[creativeType] = @([credential longLongValue]);
        }
    }];
    
    self.creativeTypeToAdUnitID = creativeTypeToAdUnitID;
}

- (NSError *)internalInitializeSDK {
    RETURN_ERROR_UNLESS([self hasNecessaryCredentials], ([NSString stringWithFormat:@"%@ needs an Account ID set up on your dashboard.", [self humanizedName]]));
    
    [HZIMSdk initWithAccountID:self.accountID];
    [HZIMSdk setLogLevel:kHZIMSDKLogLevelError];
    
    // Demographic Information
    [self updatedLocation];
    
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZIMSdk hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return @"inmobi";
}

+ (NSString *)humanizedName {
    return kHZAdapterInMobiHumanized;
}

+ (NSString *)sdkVersion
{
    return [HZIMSdk getVersion];
}

- (HZCreativeType)supportedCreativeTypes
{
    return HZCreativeTypeStatic | HZCreativeTypeVideo | HZCreativeTypeIncentivized | HZCreativeTypeBanner;
}

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    return self.creativeTypeToAdUnitID[@(creativeType)] != nil;
}

- (BOOL) hasNecessaryCredentials {
    return self.accountID != nil;
}

- (void)internalPrefetchAdWithOptions:(HZAdapterFetchOptions *)options
{
    InMobiAdUnitID *placementIDNumber = self.creativeTypeToAdUnitID[@(options.creativeType)];
    const long long placementID = [placementIDNumber longLongValue];
    
    HZIMInterstitial *ad = self.adDictionary[@(options.creativeType)];
    if (!ad) {
        self.adDictionary[@(options.creativeType)] = [self instantiateAdWithPlacementID:placementID];
    }
    
    if (options.creativeType == HZCreativeTypeIncentivized && self.backupRewardedVideo == nil) {
        self.backupRewardedVideo = [self instantiateAdWithPlacementID:placementID];
    }
}

- (HZIMInterstitial *)instantiateAdWithPlacementID:(const long long)placementID {
    HZIMInterstitial *ad = [[HZIMInterstitial alloc] initWithPlacementId:placementID delegate:self];
    ad.extras = [[self class] extrasDictionary];
    [ad load];
    return ad;
}

+ (NSDictionary *)extrasDictionary {
    return @{@"tp": @"c_heyzap", @"tp-ver": SDK_VERSION};;
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    HZIMInterstitial *const ad = self.adDictionary[@(dataProvider.creativeType)];
    return [ad isReady];
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options
{
    HZIMInterstitial *const ad = self.adDictionary[@(options.creativeType)];
    if (ad) {
        [ad showFromViewController:options.viewController];
    } else {
        NSString *const description = [NSString stringWithFormat:@"The InMobi adapter didn't have an ad for creative type %@ prefetched, but was asked to show an ad.",NSStringFromCreativeType(options.creativeType)];
        NSError *const error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: description}];
        [self.delegate adapterDidFailToShowAd:self error:error];
    }
}

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options placementIDOverride:(nullable NSString *)placementIDOverride reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    InMobiAdUnitID *bannerID =  self.creativeTypeToAdUnitID[@(HZCreativeTypeBanner)];
    if (bannerID) {
        return [[HZInMobiBannerAdapter alloc] initWithAdPlacementID:[bannerID longLongValue]
                                                            options:options
                                                  reportingDelegate:reportingDelegate
                                                      parentAdapter:self];
    } else {
        return nil;
    }
}

#pragma mark - Demographics

- (void)updatedLocation {
    [HZIMSdk setLocation:self.delegate.demographics.location];
}

#pragma mark - Logging

- (void) toggleLogging {
    [HZIMSdk setLogLevel:[self isLoggingEnabled] ? kHZIMSDKLogLevelDebug : kHZIMSDKLogLevelNone];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"HZIMInterstitialDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)clearAdForCreativeType:(HZCreativeType)creativeType {
    [self.adDictionary removeObjectForKey:@(creativeType)];
    if (creativeType == HZCreativeTypeIncentivized && self.backupRewardedVideo) {
        self.adDictionary[@(HZCreativeTypeIncentivized)] = self.backupRewardedVideo;
    }
}

#pragma mark - HZIMInterstitialDelegate

/**
 * Notifies the delegate that the interstitial has finished loading
 */
- (void)interstitialDidFinishLoading:(HZIMInterstitial*)interstitial {
    HZDLog(@"InMobi loaded ad");
    [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackAvailable
                                               forNetwork:[self name]];
}
/**
 * Notifies the delegate that the interstitial has failed to load with some error.
 */
- (void)interstitial:(HZIMInterstitial*)interstitial didFailToLoadWithError:(HZIMRequestStatus*)error {
    const HZCreativeType creativeType = [self creativeTypeForInterstitial:interstitial];
    
    HZELog(@"InMobi failed to load ad (%@) of creative type: %@ with error: %@", interstitial, NSStringFromCreativeType(creativeType), error);
    
    // Don't consider the backup rewarded video as failure that should count towards skipping to the next network.
    if (interstitial == self.backupRewardedVideo) {
        self.backupRewardedVideo = nil;
        return;
    }

    
    NSError *const castedError = (NSError *)error;
    
    if (castedError.code != kIMStatusCodeEarlyRefreshRequest && castedError.code != kIMStatusCodeAdActive) {
        [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackFetchFailed
                                                   forNetwork:[self name]];
        [self setLastFetchError:castedError forAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:creativeType]];
        
        [self clearAdForCreativeType:creativeType];
    }
}
/**
 * Notifies the delegate that the interstitial would be presented.
 */
- (void)interstitialWillPresent:(HZIMInterstitial*)interstitial {
    HZILog(@"InMobi will present interstitial: %@",interstitial);
    const HZCreativeType creativeType = [self creativeTypeForInterstitial:interstitial];
    if (creativeType == HZCreativeTypeUnknown) {
        HZELog(@"InMobi adapter found unknown creative type in %@",NSStringFromSelector(_cmd));
    } else if (creativeType != HZCreativeTypeStatic) {
        [self.delegate adapterWillPlayAudio:self];
    }
}
/**
 * Notifies the delegate that the interstitial has been presented.
 */
- (void)interstitialDidPresent:(HZIMInterstitial *)interstitial {
    HZILog(@"InMobi did present interstitial: %@",interstitial);
    [self.delegate adapterDidShowAd:self];
}
/**
 * Notifies the delegate that the interstitial has failed to present with some error.
 */
- (void)interstitial:(HZIMInterstitial*)interstitial didFailToPresentWithError:(HZIMRequestStatus*)error {
    HZILog(@"InMobi did fail to present interstitial: %@ with error: %@",interstitial, error);
    const HZCreativeType creativeType = [self creativeTypeForInterstitial:interstitial];
    NSDictionary *const userInfo = @{
                                     NSLocalizedDescriptionKey:@"Adapter failed to present",
                                     NSUnderlyingErrorKey: error,
                                     };
    [self.delegate adapterDidFailToShowAd:self error:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:userInfo]];
    [self clearAdForCreativeType:creativeType];
}
/**
 * Notifies the delegate that the interstitial will be dismissed.
 */
- (void)interstitialWillDismiss:(HZIMInterstitial*)interstitial {
    HZILog(@"InMobi will dismiss interstitial: %@",interstitial);
}
/**
 * Notifies the delegate that the interstitial has been dismissed.
 */
- (void)interstitialDidDismiss:(HZIMInterstitial*)interstitial {
    HZILog(@"InMobi did dismiss interstitial: %@",interstitial);
    const HZCreativeType creativeType = [self creativeTypeForInterstitial:interstitial];
    
    if (creativeType == HZCreativeTypeUnknown) {
        HZELog(@"Unknown creative type in %@",NSStringFromSelector(_cmd));
    } else if (creativeType != HZCreativeTypeStatic) {
        [self.delegate adapterDidFinishPlayingAudio:self];
    }
    
    [self.delegate adapterDidDismissAd:self];
    
    [self clearAdForCreativeType:creativeType];
}
/**
 * Notifies the delegate that the interstitial has been interacted with.
 */
- (void)interstitial:(HZIMInterstitial*)interstitial didInteractWithParams:(NSDictionary*)params {
    // I've only seem the `params` dictionary be `nil` in testing. InMobi hasn't responded to my email asking for details about this.
    HZDLog(@"InMobi didInteractWithParams dictionary: %@",params);
    [self.delegate adapterWasClicked:self];
}
/**
 * Notifies the delegate that the user has performed the action to be incentivised with.
 */
- (void)interstitial:(HZIMInterstitial*)interstitial rewardActionCompletedWithRewards:(NSDictionary*)rewards {
    // Afaict, InMobi doesn't allow skipping videos ever. I asked the if there was a case where the incentivized ad might not be complete, but they haven't responded.
    HZDLog(@"InMobi rewardActionCompletedWithRewards dictionary = %@",rewards);
    [self.delegate adapterDidCompleteIncentivizedAd:self];
}
/**
 * Notifies the delegate that the user will leave application context.
 */
- (void)userWillLeaveApplicationFromInterstitial:(HZIMInterstitial*)interstitial {
    [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackLeaveApplication forNetwork:[self name]];
}

- (HZCreativeType)creativeTypeForInterstitial:(HZIMInterstitial *)interstitial {
    __block HZCreativeType creativeType = HZCreativeTypeUnknown;
    [self.adDictionary enumerateKeysAndObjectsUsingBlock:^(HZCreativeTypeObject * _Nonnull creativeTypeKey, HZIMInterstitial * _Nonnull interstitialValue, BOOL * _Nonnull stop) {
        if (interstitial == interstitialValue) {
            creativeType = [creativeTypeKey unsignedIntegerValue];
            *stop = YES;
        }
    }];
    return creativeType;
}


@end
