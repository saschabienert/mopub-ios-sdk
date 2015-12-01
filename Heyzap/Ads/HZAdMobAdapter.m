//
//  HZAdMobProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdMobAdapter.h"
#import "HZGADInterstitial.h"
#import "HZGADRequest.h"
#import <UIKit/UIKit.h>
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZAdMobBannerAdapter.h"
#import "HeyzapMediation.h"
#import "HeyzapAds.h"
#import "HZBaseAdapter_Internal.h"
#import "HZShowOptions_Private.h"

#import "HZGADAdLoader.h"
#import "HZGADNativeAppInstallAdLoaderDelegate.h"
#import "HZAdMobNativeRequester.h"

typedef NSString AdMobPlacementID;

@interface HZAdMobAdapter() <HZGADInterstitialDelegate>

@property (nonatomic, strong) NSMutableDictionary<HZCreativeTypeObject *, NSMutableDictionary <AdMobPlacementID *, HZGADInterstitial *> *> *adDictionary; // outer key: creativeType, inner key: placement ID
@property (nonatomic, strong) NSMutableDictionary<HZCreativeTypeObject *, NSMutableDictionary <AdMobPlacementID *, NSError *> *> *adErrorsDictionary; // outer key: creativeType, inner key: placement ID

// TODO: Move these to a dictionary keyed off creativeType
@property (nonatomic, strong) AdMobPlacementID *interstitialAdUnitID;
@property (nonatomic, strong) AdMobPlacementID *videoAdUnitID;
@property (nonatomic, strong) AdMobPlacementID *bannerAdUnitID;
@property (nonatomic, strong) AdMobPlacementID *nativeAdUnitID;

@property (nonatomic, strong) NSMutableDictionary<AdMobPlacementID *, HZAdMobNativeRequester *> *nativePlacementToRequester;

@end

@implementation HZAdMobAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
{
    static HZAdMobAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZAdMobAdapter alloc] init];
        proxy.forwardingDelegate = [HZAdapterDelegate new];
        proxy.forwardingDelegate.adapter = proxy;
    });
    return proxy;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _adDictionary = [[NSMutableDictionary alloc] init];
        _adErrorsDictionary = [[NSMutableDictionary alloc] init];
        _nativePlacementToRequester = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)loadCredentials {
    self.interstitialAdUnitID = [HZDictionaryUtils objectForKey:@"ad_unit_id" ofClass:[NSString class] dict:self.credentials];
    self.videoAdUnitID = [HZDictionaryUtils objectForKey:@"video_ad_unit_id" ofClass:[NSString class] dict:self.credentials];
    self.bannerAdUnitID = [HZDictionaryUtils objectForKey:@"banner_ad_unit_id" ofClass:[NSString class] dict:self.credentials];
    self.nativeAdUnitID = [HZDictionaryUtils objectForKey:@"native_ad_unit_id" ofClass:[NSString class] dict:self.credentials];
}

#pragma mark - Adapter Protocol

- (NSError *)internalInitializeSDK {
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZGADInterstitial hzProxiedClassIsAvailable] && [HZGADRequest hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return HZNetworkAdMob;
}

+ (NSString *)humanizedName
{
    return kHZAdapterAdMobHumanized;
}

+ (NSString *)sdkVersion {
    return [HZGADRequest sdkVersion];
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    if ([dataProvider creativeType] == HZCreativeTypeNative) {
        AdMobPlacementID *const placementID = [dataProvider placementIDOverride] ?: self.nativeAdUnitID;
        HZAdMobNativeRequester *requester = self.nativePlacementToRequester[placementID];
        return requester.adCount > 0;
    } else {
        HZGADInterstitial *ad = [self adWithMetadata:dataProvider];
        return ad && ad.isReady;
    }
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeStatic | HZCreativeTypeVideo | HZCreativeTypeBanner | HZCreativeTypeNative;
}

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            return self.interstitialAdUnitID != nil;
        }
        case HZCreativeTypeVideo: {
            return self.videoAdUnitID != nil;
        }
        case HZCreativeTypeBanner: {
            return self.bannerAdUnitID != nil;
        }
        case HZCreativeTypeNative: {
            return self.nativeAdUnitID != nil;
        }
        case HZCreativeTypeIncentivized:
        case HZCreativeTypeUnknown: {
            return NO;
        }
    }
}

- (void)internalPrefetchAdWithOptions:(HZAdapterFetchOptions *)options
{
    switch (options.creativeType) {
        case HZCreativeTypeNative: {
            [self fetchNativeWithOptions:options];
            return;
        }
        case HZCreativeTypeStatic: {
            AdMobPlacementID *adUnitID = options.placementIDOverride ?: self.interstitialAdUnitID;
            HZAssert(adUnitID, @"Need an interstitial ad unit ID by this point");
            
            HZMediationAdAvailabilityDataProvider *updatedDataProvider = [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:options.creativeType placementIDOverride:adUnitID];
            [self fetchNonNativeWithMetadata:updatedDataProvider];
            break;
        }
        case HZCreativeTypeVideo: {
            AdMobPlacementID *adUnitID = options.placementIDOverride ?: self.videoAdUnitID;
            HZAssert(adUnitID, @"Need a video ad unit ID by this point");
            
            HZMediationAdAvailabilityDataProvider *updatedDataProvider = [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:options.creativeType placementIDOverride:adUnitID];
            [self fetchNonNativeWithMetadata:updatedDataProvider];
            break;
        }
        default: {
            return;
        }
    }
}

- (void)fetchNonNativeWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)metadata {
    HZGADInterstitial *currentAd = [self adWithMetadata:metadata];
    NSString *const placementID = [metadata placementIDOverride];
    if (currentAd
        && !currentAd.hasBeenUsed) {
        // If we have an ad already out fetching, don't start up a re-fetch.
        return;
    }
    
    HZDLog(@"Initializing AdMob Ad with %@AdUnitID: %@", (metadata.creativeType == HZCreativeTypeStatic ? @"interstitial" : @"video"), placementID);
    
    HZGADInterstitial *newAd;
    
    if ([HZGADInterstitial respondsToSelector:@selector(initWithAdUnitID:)]) {
        newAd = [[HZGADInterstitial alloc] initWithAdUnitID:placementID];
    } else {
        newAd = [[HZGADInterstitial alloc] init];
        [newAd setAdUnitID:placementID];
    }
    
    newAd.delegate = self.forwardingDelegate;
    [self setAd:newAd forMetadata:metadata];
    
    HZGADRequest *request = [HZGADRequest request];
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    [newAd loadRequest:request];
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options
{
    HZGADInterstitial *ad = [self adWithMetadata:options];
    [ad presentFromRootViewController:options.viewController];
}

#pragma mark - Delegate callbacks

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"GADInterstitialDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)interstitial:(HZGADInterstitial *)ad didFailToReceiveAdWithError:(HZGADRequestError *)error
{
    HZMediationAdAvailabilityDataProvider *metadata = [self metadataForAd:ad];
    [self setAd:nil forMetadata:metadata];
    
    NSError *wrappedError = [NSError errorWithDomain:kHZMediationDomain
                                                code:1
                                            userInfo:@{kHZMediatorNameKey: @"AdMob",
                                                       NSUnderlyingErrorKey: error}];
    [self setLastFetchError:wrappedError forAdsWithMatchingMetadata:metadata];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)interstitialWillPresentScreen:(HZGADInterstitial *)ad {
    [self.delegate adapterDidShowAd:self];
    [self.delegate adapterWillPlayAudio:self];
}

- (void)interstitialDidDismissScreen:(HZGADInterstitial *)ad
{
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
    
    [self setAd:nil forMetadata:[self metadataForAd:ad]];
}

// As far as I can tell, this means a click.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad
{
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    [self clearLastFetchErrorForAdsWithMatchingMetadata:[self metadataForAd:ad]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options placementIDOverride:(nullable AdMobPlacementID *)placementIDOverride reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZAdMobBannerAdapter alloc] initWithAdUnitID:(placementIDOverride ?: self.bannerAdUnitID) options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

- (void) setLastFetchError:(NSError *)error forAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    AdMobPlacementID *placementIDToUse = [self defaultOrOverridenPlacementIDForAdWithMetadata:dataProvider];
    NSMutableDictionary * errorsForCreativeType = self.adErrorsDictionary[@(dataProvider.creativeType)];
    
    if (!errorsForCreativeType) {
        errorsForCreativeType = [[NSMutableDictionary alloc] init];
        self.adErrorsDictionary[@(dataProvider.creativeType)] = errorsForCreativeType;
    }
    if (error) {
        errorsForCreativeType[placementIDToUse] = error;
    } else {
        [errorsForCreativeType removeObjectForKey:placementIDToUse];
    }
    
}

- (NSError *) lastFetchErrorForAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    AdMobPlacementID *placementIDToUse = [self defaultOrOverridenPlacementIDForAdWithMetadata:dataProvider];
    NSDictionary *errorsForCreativeType = self.adErrorsDictionary[@(dataProvider.creativeType)];
    
    if (!errorsForCreativeType) {
        return nil;
    } else {
        return errorsForCreativeType[placementIDToUse];
    }
}

#pragma mark - Utilities

- (HZGADInterstitial *) adWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    AdMobPlacementID *placementIDToUse = [self defaultOrOverridenPlacementIDForAdWithMetadata:dataProvider];
    NSDictionary *adsForCreativeType = self.adDictionary[@(dataProvider.creativeType)];
    
    if (!adsForCreativeType) {
        return nil;
    } else {
        return adsForCreativeType[placementIDToUse];
    }
}

- (void) setAd:(HZGADInterstitial *)ad forMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    NSMutableDictionary * adsForCreativeType = self.adDictionary[@(dataProvider.creativeType)];
    if (!adsForCreativeType) {
        adsForCreativeType = [[NSMutableDictionary alloc] init];
        self.adDictionary[@(dataProvider.creativeType)] = adsForCreativeType;
    }
    if (ad) {
        adsForCreativeType[dataProvider.placementIDOverride] = ad;
    } else {
        [adsForCreativeType removeObjectForKey:dataProvider.placementIDOverride];
    }
}

- (HZCreativeType)creativeTypeForAd:(HZGADInterstitial *)ad {
    NSArray *supportedCreativeTypes = @[@(HZCreativeTypeStatic), @(HZCreativeTypeVideo)];
    
    for (HZCreativeTypeObject *creativeTypeObject in supportedCreativeTypes) {
        if (self.adDictionary[creativeTypeObject] && [[self.adDictionary[creativeTypeObject] allValues] containsObject:ad]) {
            return hzCreativeTypeFromObject(creativeTypeObject);
        }
    }
    
    HZELog(@"AdMob adapter in an unexpected state... it was looking for the creative type for an ad in its inventory, but no ad was present. Please report this to support@heyzap.com . Ad: %@", ad);
    return HZCreativeTypeUnknown;
}

- (HZMediationAdAvailabilityDataProvider *) metadataForAd:(HZGADInterstitial *)ad {
    const HZCreativeType creativeType = [self creativeTypeForAd:ad];
    return [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:creativeType placementIDOverride:ad.adUnitID];
}

- (AdMobPlacementID *) defaultOrOverridenPlacementIDForAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    AdMobPlacementID *defaultPlacementID = (dataProvider.creativeType == HZCreativeTypeStatic ? self.interstitialAdUnitID : self.videoAdUnitID);
    return dataProvider.placementIDOverride ?: defaultPlacementID;
}

- (void)fetchNativeWithOptions:(HZAdapterFetchOptions *)options {
    AdMobPlacementID *const placementID = options.placementIDOverride ?: self.nativeAdUnitID;
    NSAssert(placementID, @"Need a native placement ID by this point");
    HZAdMobNativeRequester *requester = self.nativePlacementToRequester[placementID];
    if (!requester) {
        requester = [[HZAdMobNativeRequester alloc] initWithNativeAdUnitID:placementID parentAdapter:self];
        self.nativePlacementToRequester[placementID] = requester;
        [requester fetchNative:options];
    }
}

- (nullable HZNativeAdAdapter *)getNativeOrError:(NSError *  _Nonnull * _Nullable)error metadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    AdMobPlacementID *const placementID = [dataProvider placementIDOverride] ?: self.nativeAdUnitID;
    HZAdMobNativeRequester *requester = self.nativePlacementToRequester[placementID];
    
    if (!requester) {
        *error = [NSError errorWithDomain:kHZMediationDomain
                                     code:1
                                 userInfo:@{NSLocalizedDescriptionKey: @"This AdMob ad unit ID has never been fetched", @"adUnit":placementID}];
        return nil;
    }
    
    HZNativeAdAdapter *adapter = [requester getNativeOrError:error metadata:dataProvider];
    if (adapter) {
        return adapter;
    } else {
        return nil;
    }
}
@end
