//
//  HZLeadboltAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZLeadboltAdapter.h"
#import "HZAppTracker.h"
#import "HeyzapMediation.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZBaseAdapter_Internal.h"

@interface HZLeadboltAdapter()

@property (nonatomic) BOOL staticCached;
@property (nonatomic) BOOL incentivizedCached;

@property (nonatomic) NSString *appAPIKey;

@end

@implementation HZLeadboltAdapter

#pragma mark - Initialization

/**
 *  The Leadbolt identifier for blended static and video.
 */
NSString * const kHZLeadboltInterstitialModule = @"inapp";
/**
 *  The Leadbolt identifier for rewarded video.
 */
NSString * const kHZLeadboltIncentivizedModule = @"video";

+ (instancetype)sharedAdapter
{
    static HZLeadboltAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZLeadboltAdapter alloc] init];
    });
    return adapter;
}

#pragma mark - Adapter Protocol

- (void)loadCredentials {
    self.appAPIKey = [HZDictionaryUtils objectForKey:@"app_api_key"
                                             ofClass:[NSString class]
                                                dict:self.credentials];
}

- (BOOL) hasNecessaryCredentials {
    return self.appAPIKey != nil;
}

- (NSError *)internalInitializeSDK {
    RETURN_ERROR_UNLESS([self hasNecessaryCredentials], ([NSString stringWithFormat:@"%@ needs an App API Key set up on your dashboard.", [self humanizedName]]));
    
    // These notifications aren't documented in AppTracker.h; this comes from http://help.leadbolt.com/ios-integration-guide/ and their sample app.
    
    NSNotificationCenter *const nc = [NSNotificationCenter defaultCenter];
    NSString *const object = @"AppFireworksNotification";
    [nc addObserver:self selector:@selector(onModuleLoaded:)  name:@"onModuleLoaded"  object:object];
    [nc addObserver:self selector:@selector(onModuleFailed:)  name:@"onModuleFailed"  object:object];
    [nc addObserver:self selector:@selector(onModuleCached:)  name:@"onModuleCached"  object:object];
    [nc addObserver:self selector:@selector(onModuleClosed:)  name:@"onModuleClosed"  object:object];
    [nc addObserver:self selector:@selector(onModuleClicked:) name:@"onModuleClicked" object:object];
    [nc addObserver:self selector:@selector(onMediaFinished:) name:@"onMediaFinished" object:object];
    
    HZDLog(@"Initializing Leadbolt with App API Key: %@",self.appAPIKey);
    [HZAppTracker startSession:self.appAPIKey]; // NB: Leadbolt must be started after registering for NSNotifications per docs.
    
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZAppTracker hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return HZNetworkLeadbolt;
}

+ (NSString *)humanizedName {
    return kHZAdapterLeadboltHumanized;
}

+ (NSString *)sdkVersion
{
    return nil;
}

- (HZCreativeType)supportedCreativeTypes
{
    // We don't currently have a way to tell if an interstitial from Leadbolt is a static or video ad.
    // Until we do, we will treat them as all static.
    return HZCreativeTypeStatic | HZCreativeTypeIncentivized;
}

- (void)internalPrefetchAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    switch (dataProvider.creativeType) {
        case HZCreativeTypeStatic: {
            HZDLog(@"Prefetching Leadbolt ad of type: %@",NSStringFromCreativeType(dataProvider.creativeType));
            [HZAppTracker loadModuleToCache:kHZLeadboltInterstitialModule];
            break;
        }
        case HZCreativeTypeIncentivized: {
            HZDLog(@"Prefetching Leadbolt ad of type: %@",NSStringFromCreativeType(dataProvider.creativeType));
            [HZAppTracker loadModuleToCache:kHZLeadboltIncentivizedModule];
            break;
        }
        default: {
            // Unsupported
            HZDLog(@"Can't prefetch Leadbolt ad of unsupported type: %@",NSStringFromCreativeType(dataProvider.creativeType));
            break;
        }
    }
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    switch (dataProvider.creativeType) {
        case HZCreativeTypeStatic: {
            return self.staticCached;
        }
        case HZCreativeTypeIncentivized: {
            return self.incentivizedCached;
        }
        default: {
            // Unsupported
            return NO;
        }
    }
}

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeStatic:
        case HZCreativeTypeIncentivized: {
            return (self.appAPIKey != nil);
        }
        default: {
            // Ad types not supported by this network
            return NO;
        }
    }
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options
{
    HZDLog(@"Requesting that Leadbolt show an ad of type: %@", NSStringFromCreativeType(options.creativeType));
    switch (options.creativeType) {
        case HZCreativeTypeStatic: {
            self.staticCached = NO;
            [HZAppTracker loadModule:kHZLeadboltInterstitialModule viewController:options.viewController];
            break;
        }
        case HZCreativeTypeIncentivized: {
            self.incentivizedCached = NO;
            [HZAppTracker loadModule:kHZLeadboltIncentivizedModule viewController:options.viewController];
            break;
        }
        default: {
            // Unsupported
            break;
        }
    }
}

#pragma mark - NSNotifications

- (void)onModuleLoaded:(NSNotification *)notification {
    // Ad shown
    HZDLog(@"Leadbolt ad shown; notification = %@",notification);
    [self.delegate adapterWillPlayAudio:self];
    [self.delegate adapterDidShowAd:self];
}

- (void)onModuleFailed:(NSNotification *)notification {
    [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackFetchFailed forNetwork:[self name]];
    const BOOL wasFailureToCache = [notification.userInfo[@"cached"] isEqualToString:@"yes"];
    
    if (wasFailureToCache) {
        HZELog(@"Mediation: Leadbolt ad failed to cache; notification = %@", notification);
        
        [self setLastFetchError:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Leadbolt ad failed to cache."}] forAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:[self creativeTypeFromNSNotification:notification]]];
    } else { // Otherwise, it failed to show
        HZELog(@"Mediation: Leadbolt ad failed to display; notification = %@", notification);
        [self.delegate adapterDidFailToShowAd:self error:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Leadbolt ad failed to display."}]];
    }
}

- (void)onModuleCached:(NSNotification *)notification {
    [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackAvailable forNetwork:[self name]];
    HZDLog(@"Leadbolt ad cached; notification = %@",notification);
    HZCreativeType creativeType = [self creativeTypeFromNSNotification:notification];
    
    if (creativeType == HZCreativeTypeStatic) {
        [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:creativeType]];
        self.staticCached = YES;
    } else if (creativeType == HZCreativeTypeIncentivized) {
        [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:creativeType]];
        self.incentivizedCached = YES;
    } else {
        HZELog(@"Unknown module type cached by Leadbolt. This shouldn't break anything, but it's unexpected. notification = %@",notification);
        // clear all the errors to be safe in this case.
        [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeStatic]];
        [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeIncentivized]];
    }
}

- (void)onModuleClosed:(NSNotification *)notification {
    HZDLog(@"Leadbolt ad closed; notification = %@",notification);
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
}

- (void)onModuleClicked:(NSNotification *)notification {
    HZDLog(@"Leadbolt ad clicked; notification = %@",notification);
    [self.delegate adapterWasClicked:self];
}

// Based on testing, this notification is only called for rewarded video.
- (void)onMediaFinished:(NSNotification *)notification {
    HZDLog(@"Leadbolt media finished; notification = %@",notification);
    
    // Rewarded videos from Leadbolt are always unskippable, as far as I can tell.
    // Jay Shah from Leadbolt says that as far as he knows, `viewCompleted` will always be true for rewarded videos.
    const BOOL incentivizedComplete = [notification.userInfo[@"viewCompleted"] isEqualToString:@"yes"];
    
    if (incentivizedComplete) {
        [self.delegate adapterDidCompleteIncentivizedAd:self];
    } else {
        [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
    }
}


#pragma mark - Utilities

- (HZCreativeType) creativeTypeFromNSNotification:(NSNotification *)notification {
    NSString *const placement = notification.userInfo[@"placement"];
    
    if ([placement isEqualToString:kHZLeadboltInterstitialModule]) {
        return HZCreativeTypeStatic;
    } else if ([placement isEqualToString:kHZLeadboltIncentivizedModule]) {
        return HZCreativeTypeIncentivized;
    } else {
        HZELog(@"Unknown module placement by Leadbolt. This shouldn't break anything, but it's unexpected. notification = %@",notification);
        return HZCreativeTypeUnknown;
    }
}

@end
