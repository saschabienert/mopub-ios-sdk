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

@interface HZChartboostAdapter()

@end

@implementation HZChartboostAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZChartboostAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZChartboostAdapter alloc] init];
    });
    return adapter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [HZChartboost setShouldDisplayLoadingViewForMoreApps:NO];
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
    NSParameterAssert(credentials);
    
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
    [HZChartboost startWithAppId:appID appSignature:appSignature delegate:self];
}

+ (NSString *)name
{
    return kHZAdapterChartboost;
}

+ (NSString *)humanizedName
{
    return kHZAdapterChartboostHumanized;
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
    
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location
                         withError:(CBLoadError)error {
    [[self class] logError:error];
    self.lastIncentivizedError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey:@"Chartboost"}];
    
}

- (void)didCacheRewardedVideo:(CBLocation)location {
    self.lastIncentivizedError = nil;
}

- (void)didClickRewardedVideo:(CBLocation)location {
    [[HZMetrics sharedInstance] logMetricsEvent:kAdClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterWasClicked: self];
}

- (void)didClickInterstitial:(CBLocation)location
{
    [[HZMetrics sharedInstance] logMetricsEvent:kAdClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterWasClicked:self];
}

- (BOOL)shouldRequestInterstitial:(CBLocation)location {
    return YES;
}

- (void)didCompleteRewardedVideo:(CBLocation)location
                      withReward:(int)reward {
    [self.delegate adapterDidCompleteIncentivizedAd: self];
}

- (void)didDismissRewardedVideo:(CBLocation)location {
    [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterDidDismissAd:self];
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
    [self.delegate adapterDidDismissAd:self];
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


@end
