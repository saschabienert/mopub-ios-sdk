//
//  HZChartboostMediator.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZChartboostAdapter.h"
#import <UIKit/UIKit.h>
#import "HZChartboost.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZLog.h"
#import "HZMetrics.h"
#import "HZMetricsAdStub.h"
#import "HeyzapMediation.h"

@interface HZChartboostAdapter()

@property (nonatomic) BOOL isPlayingAudio;

@end

@implementation HZChartboostAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZChartboostAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZChartboostAdapter alloc] init];
        adapter.forwardingDelegate = [HZAdapterDelegate new];
        adapter.forwardingDelegate.adapter = adapter;
    });
    return adapter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [HZChartboost setShouldPrefetchVideoContent:YES];
    }
    return self;
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable
{
    return [HZChartboost hzProxiedClassIsAvailable];
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    HZParameterAssert(credentials);
    
    NSError *error;
    NSString *appID = [HZDictionaryUtils objectForKey:@"app_id" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *appSignature = [HZDictionaryUtils objectForKey:@"app_signature" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    HZChartboostAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        [[self sharedInstance] setupChartboostWithAppID:appID appSignature:appSignature];
    }
    
    return nil;
}

- (void)setupChartboostWithAppID:(NSString *)appID appSignature:(NSString *)appSignature
{
    [HZChartboost startWithAppId:appID appSignature:appSignature delegate:self.forwardingDelegate];
}

+ (NSString *)name
{
    return kHZAdapterChartboost;
}

+ (NSString *)humanizedName
{
    return kHZAdapterChartboostHumanized;
}

- (HZNetwork)network {
    return HZNetworkChartboost;
}

+ (NSString *)sdkVersion {
    return nil; // Chartboost doesn't provide the version.
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    switch (type) {
        case HZAdTypeInterstitial: {
            [HZChartboost cacheInterstitial: [self.delegate countryCode]];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZChartboost cacheRewardedVideo:[self.delegate countryCode]];
            break;
        }
        case HZAdTypeBanner:
        case HZAdTypeVideo: {
            // Unsupported
        }
    }
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    switch (type) {
        case HZAdTypeIncentivized: {
            return [HZChartboost hasRewardedVideo: [self.delegate countryCode]];
        }
        case HZAdTypeInterstitial:
            return [HZChartboost hasInterstitial: [self.delegate countryCode]];
        case HZAdTypeBanner:
        case HZAdTypeVideo:
            return NO;
    }
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    switch (type) {
        case HZAdTypeInterstitial:
            [HZChartboost showInterstitial: [self.delegate countryCode]];
            break;
        case HZAdTypeIncentivized:
            [HZChartboost showRewardedVideo: [self.delegate countryCode]];
            break;
        case HZAdTypeBanner:
        case HZAdTypeVideo:
            // Unsupported
            break;
    }

    self.metricsStub = [[HZMetricsAdStub alloc] initWithTag:options.tag adUnit:NSStringFromAdType(type)];
    [[HZMetrics sharedInstance] logTimeSinceShowAdFor:kShowAdTimeTillAdIsDisplayedKey withProvider:self.metricsStub network:[self name]];
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

#pragma mark - Chartboost Delegate

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"ChartboostDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

/*
 * Chartboost Delegate Methods
 *
 */

/*
 * didFailToLoadInterstitial
 *
 * This is called when an interstitial has failed to load. The error enum specifies
 * the reason of the failure
 */

- (void)didFailToLoadInterstitial:(NSString *)location withError:(CBLoadError)error {
    [[self class] logError:error];
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey: @"Chartboost"}];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self network]];
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location
                         withError:(CBLoadError)error {
    [[self class] logError:error];
    self.lastIncentivizedError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey:@"Chartboost"}];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self network]];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
    self.lastIncentivizedError = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self network]];
}

- (void)didClickRewardedVideo:(CBLocation)location {
    [[HZMetrics sharedInstance] logMetricsEvent:kAdClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterWasClicked: self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self network]];
}

- (void)didClickInterstitial:(CBLocation)location
{
    [[HZMetrics sharedInstance] logMetricsEvent:kAdClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterWasClicked:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self network]];
}

- (BOOL)shouldRequestInterstitial:(CBLocation)location {
    return YES;
}

- (void)didCompleteRewardedVideo:(CBLocation)location
                      withReward:(int)reward {
    [self.delegate adapterDidCompleteIncentivizedAd: self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultComplete forNetwork: [self network]];
}

- (void)didDismissRewardedVideo:(CBLocation)location {
    [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self maybeFinishPlayingAudio];
    [self.delegate adapterDidDismissAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultIncomplete forNetwork: [self network]];
}



/*
 * didCacheInterstitial
 *
 * Passes in the location name that has successfully been cached.
 *
 * Is fired on:
 * - All assets loaded
 * - Triggered by cacheInterstitial
 *
 * Notes:
 * - Similar to this is: (BOOL)hasCachedInterstitial:(NSString *)location;
 * Which will return true if a cached interstitial exists for that location
 */

- (void)didCacheInterstitial:(CBLocation)location {
    self.lastInterstitialError = nil;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self network]];
}

/*
 * didDismissInterstitial
 *
 * This is called when an interstitial is dismissed
 *
 * Is fired on:
 * - Interstitial click
 * - Interstitial close
 *
 * #Pro Tip: Use the delegate method below to immediately re-cache interstitials
 */
- (void)didDismissInterstitial:(CBLocation)location {
    [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self maybeFinishPlayingAudio];
    [self.delegate adapterDidDismissAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackHide forNetwork: [self network]];
}

/**
 *  More Apps
 */
- (void)didFailToLoadMoreApps:(CBLocation)location withError:(CBLoadError)error {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"moreapps-fetch_failed" forNetwork: [self network]];
}

- (void)didCacheMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"moreapps-available" forNetwork: [self network]];
}

- (void)didDismissMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"moreapps-hide" forNetwork: [self network]];
}

- (void)didCloseMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"moreapps-hide" forNetwork: [self network]];
}

- (void)didClickMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"moreapps-click" forNetwork: [self network]];
}

- (void)didDisplayMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: @"moreapps-show" forNetwork: [self network]];
}


/*
 * shouldRequestInterstitialsInFirstSession
 *
 * This sets logic to prevent interstitials from being displayed until the second startSession call
 *
 * The default is YES, meaning that it will always request & display interstitials.
 * If your app displays interstitials before the first time the user plays the game, implement this method to return NO.
 */

- (BOOL)shouldRequestInterstitialsInFirstSession {
    return YES;
}

+ (void)logError:(CBLoadError)error {
    switch(error){
        case CBLoadErrorInternetUnavailable: {
            HZDLog(@"Chartboost: Failed to load Interstitial, no Internet connection !");
        } break;
        case CBLoadErrorInternal: {
            HZDLog(@"Chartboost: Failed to load Interstitial, internal error !");
        } break;
        case CBLoadErrorNetworkFailure: {
            HZDLog(@"Chartboost: Failed to load Interstitial, network error !");
        } break;
        case CBLoadErrorWrongOrientation: {
            HZDLog(@"Chartboost: Failed to load Interstitial, wrong orientation !");
        } break;
        case CBLoadErrorTooManyConnections: {
            HZDLog(@"Chartboost: Failed to load Interstitial, too many connections !");
        } break;
        case CBLoadErrorFirstSessionInterstitialsDisabled: {
            HZDLog(@"Chartboost: Failed to load Interstitial, first session !");
        } break;
        case CBLoadErrorNoAdFound : {
            HZDLog(@"Chartboost: Failed to load Interstitial, no ad found !");
        } break;
        case CBLoadErrorSessionNotStarted : {
            HZDLog(@"Chartboost: Failed to load Interstitial, session not started !");
        } break;
        default: {
            HZDLog(@"Chartboost: Failed to load Interstitial, unknown error !");
        }
    }
}

- (void)maybeFinishPlayingAudio {
    if (self.isPlayingAudio) {
        [self.delegate adapterDidFinishPlayingAudio:self];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioFinished forNetwork: [self network]];
    }
    self.isPlayingAudio = NO;
}

- (void)willDisplayVideo:(CBLocation)location {
    self.isPlayingAudio = YES;
    [self.delegate adapterWillPlayAudio:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioStarting forNetwork: [self network]];
}


@end
