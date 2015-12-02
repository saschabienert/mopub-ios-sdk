//
//  HZFacebookAdapter.m
//  Heyzap
//
//  Created by David Stumm on 12/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZFacebookAdapter.h"
#import "HZFBInterstitialAd.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZBannerAd.h"
#import "HZFBAdView.h"
#import "HZFBBannerAdapter.h"
#import "HZBannerAdOptions_Private.h"
#import "HZShowOptions_Private.h"
#import "HeyzapMediation.h"
#import "HeyzapAds.h"
#import "HZBaseAdapter_Internal.h"
#import "HZFBAdSettings.h"
#import "HZDevice.h"
#import "HZFBNativeAdAdapter.h"
#import "HZFBNativeAdsManager.h"
#import "HZFBNativeAdsManagerDelegate.h"

typedef NSString FacebookPlacementID;

@interface HZFacebookAdapter() <HZFBInterstitialAdDelegate, HZFBNativeAdsManagerDelegate>

@property (nonatomic, strong) FacebookPlacementID *placementID;
@property (nonatomic, strong) FacebookPlacementID *bannerPlacementID;
@property (nonatomic, strong) FacebookPlacementID *nativePlacementID;
@property (nonatomic, strong) NSMutableDictionary <FacebookPlacementID *, HZFBInterstitialAd *> *interstitialAds;
@property (nonatomic, strong) NSMutableDictionary <FacebookPlacementID *, NSError *> *interstitialAdErrors;

@property (nonatomic, strong) NSMutableDictionary <FacebookPlacementID *, HZFBNativeAdsManager *> *nativeAdsManagers;

@end

@implementation HZFacebookAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter {
    static HZFacebookAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZFacebookAdapter alloc] init];
        proxy.forwardingDelegate = [HZAdapterDelegate new];
        proxy.forwardingDelegate.adapter = proxy;
    });
    return proxy;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _interstitialAds = [[NSMutableDictionary alloc] init];
        _interstitialAdErrors = [[NSMutableDictionary alloc] init];
        _nativeAdsManagers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)loadCredentials {
    self.placementID = [HZDictionaryUtils
                        objectForKey:@"placement_id"
                        ofClass:[NSString class]
                        dict:self.credentials];
    self.bannerPlacementID = [HZDictionaryUtils
                              objectForKey:@"banner_placement_id"
                              ofClass:[NSString class]
                              dict:self.credentials];
    self.nativePlacementID = [HZDictionaryUtils
                              objectForKey:@"native_placement_id"
                              ofClass:[NSString class]
                              dict:self.credentials];
}

- (void) toggleLogging {
    // method available after FAN version 4.1.0
    if ([HZFBAdSettings respondsToSelector:@selector(setLogLevel:)]) {
        [HZFBAdSettings setLogLevel:([self isLoggingEnabled] ? HZFBAdLogLevelVerbose : HZFBAdLogLevelError)]; // leave error logs on
    }
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable {
    return [HZFBInterstitialAd hzProxiedClassIsAvailable]
    && [HZFBAdView hzProxiedClassIsAvailable]
    && hziOS7Plus();
}

+ (NSString *)name {
    return HZNetworkFacebook;
}

+ (NSString *) humanizedName {
    return kHZAdapterFacebookHumanized;
}

+ (NSString *)sdkVersion {
    return nil;
}

- (NSError *)internalInitializeSDK {
    [self toggleLogging];
    return nil;
}

- (NSString *)testActivityInstructions {
    return @"Facebook Audience Network will only show ads if you have Facebook installed and are logged in, or are using a simulator. You can use [FBAdSettings addTestDevice:<device hash>] to work around this. FAN will print your device hash to the Xcode console.";
}

- (HZCreativeType) supportedCreativeTypes {
    return HZCreativeTypeStatic | HZCreativeTypeBanner | HZCreativeTypeNative;
}

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            return self.placementID != nil;
        }
        case HZCreativeTypeBanner: {
            return self.bannerPlacementID != nil;
        }
        case HZCreativeTypeNative: {
            return self.nativePlacementID != nil;
        }
            
        default: {
            return NO;
        }
    }
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    if ([dataProvider creativeType] == HZCreativeTypeNative) {
        FacebookPlacementID *const placement = (dataProvider.placementIDOverride ?: self.nativePlacementID);
        HZFBNativeAdsManager *const manager = self.nativeAdsManagers[placement];
        return manager.isValid && manager.uniqueNativeAdCount > 0;
    } else {
        HZFBInterstitialAd *ad = self.interstitialAds[dataProvider.placementIDOverride ?: self.placementID];
        return ad && ad.isAdValid;
    }
}

- (void)internalPrefetchAdWithOptions:(HZAdapterFetchOptions *)options {
    if (options.creativeType == HZCreativeTypeNative) {
        [self fetchNativeWithOptions:options];
        return;
    }
    
    FacebookPlacementID *const placement = (options.placementIDOverride ?: self.placementID);
    HZAssert(placement, @"Need a Placement ID by this point");
    
    if (self.interstitialAds[placement]) {
        // If we have an interstitial already out fetching, don't start up a re-fetch. This differs from the `hasAdWithMetadata:` check because we don't check `isAdValid`.
        return;
    }
    
    HZDLog(@"Initializing Facebook Audience Network interstitial ad with placement ID: %@", placement);
    HZFBInterstitialAd *newAd = [[HZFBInterstitialAd alloc] initWithPlacementID: placement];
    self.interstitialAds[placement] = newAd;
    newAd.delegate = self.forwardingDelegate;
    
    [newAd loadAd];
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options {
    [self.interstitialAds[options.placementIDOverride ?: self.placementID] showAdFromRootViewController:options.viewController];
}

- (void) setLastFetchError:(NSError *)error forAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    if (error) {
        [self.interstitialAdErrors setObject:error forKey:dataProvider.placementIDOverride ?: self.placementID];
    } else {
        [self.interstitialAdErrors removeObjectForKey:dataProvider.placementIDOverride ?: self.placementID];
    }
}

- (NSError *) lastFetchErrorForAdsWithMatchingMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    return self.interstitialAdErrors[dataProvider.placementIDOverride ?: self.placementID];
}

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options placementIDOverride:(nullable FacebookPlacementID *)placementIDOverride reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZFBBannerAdapter alloc] initWithAdUnitId:(placementIDOverride ?: self.bannerPlacementID) options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

#pragma mark - Native

- (void)fetchNativeWithOptions:(HZAdapterFetchOptions *)options {
    FacebookPlacementID *const placement = (options.placementIDOverride ?: self.nativePlacementID);
    HZAssert(placement, @"Need a Placement ID by this point");
    HZFBNativeAdsManager *manager = self.nativeAdsManagers[placement];
    
    if (!manager) {
        manager = [[HZFBNativeAdsManager alloc] initWithPlacementID:placement forNumAdsRequested:[options.uniqueNativeAdsToFetch unsignedIntegerValue]];
        manager.mediaCachePolicy = HZFBNativeAdsCachePolicyNone;
        manager.delegate = self;
        // (FAN will autorefresh the native ads, so there's no need to call `loadAds` more than once)
        [manager loadAds];
        self.nativeAdsManagers[placement] = manager;
    }
}

- (nullable HZNativeAdAdapter *)getNativeAdForMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    FacebookPlacementID *const placement = (dataProvider.placementIDOverride ?: self.nativePlacementID);
    HZFBNativeAdsManager *manager = self.nativeAdsManagers[placement];
    
    if (!manager) {
        HZELog(@"The Facebook Placement ID: %@ has never been fetched.",placement);
        return nil;
    }
    
    HZFBNativeAd *nativeAd = [manager nextNativeAd];
    if (nativeAd) {
        return [[HZFBNativeAdAdapter alloc] initWithNativeAd:nativeAd parentAdapter:self];
    } else {
        return nil;
    }
}


#pragma mark - Facebook Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"FBInterstitialAdDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)interstitialAdDidClick:(HZFBInterstitialAd *)interstitialAd {
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialAdDidClose:(HZFBInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd:self];
    [self.interstitialAds removeObjectForKey:interstitialAd.placementID];
}

- (void)interstitialAdWillClose:(HZFBInterstitialAd *)interstitialAd {
    
}

- (void)interstitialAdDidLoad:(HZFBInterstitialAd *)interstitialAd {
    [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeStatic placementIDOverride:interstitialAd.placementID]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void)interstitialAd:(HZFBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    [self setLastFetchError:[NSError errorWithDomain:kHZMediationDomain
                                                code:1
                                            userInfo:@{kHZMediatorNameKey: @"Facebook", NSUnderlyingErrorKey: error}]
            forAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeStatic placementIDOverride:interstitialAd.placementID]];
    [self.interstitialAds removeObjectForKey:interstitialAd.placementID];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)interstitialAdWillLogImpression:(HZFBInterstitialAd *)interstitialAd {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFacebookLoggingImpression forNetwork: [self name]];
    [self.delegate adapterDidShowAd:self];
}

#pragma mark - Native Delegation

- (void)nativeAdsLoaded {
    HZDLog(@"FAN native ads loaded");
}

- (void)nativeAdsFailedToLoadWithError:(nonnull NSError *)error {
    HZELog(@"Error loading Facebook native ads: %@",error);
}

@end
