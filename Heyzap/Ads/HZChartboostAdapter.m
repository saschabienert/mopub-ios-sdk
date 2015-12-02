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
#import "HeyzapMediation.h"
#import "HZBaseAdapter_Internal.h"

@interface HZChartboostAdapter()

@property (nonatomic) NSString *appID;
@property (nonatomic) NSString *appSignature;

@property (nonatomic) BOOL isPlayingAudio;

@end

@implementation HZChartboostAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
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

- (void)loadCredentials {
    self.appID = [HZDictionaryUtils objectForKey:@"app_id" ofClass:[NSString class] dict:self.credentials];
    self.appSignature = [HZDictionaryUtils objectForKey:@"app_signature" ofClass:[NSString class] dict:self.credentials];
}

- (BOOL) hasNecessaryCredentials {
    return self.appID != nil && self.appSignature != nil;
}

- (NSString *)testActivityInstructions {
    return @"If you have trouble receiving Chartboost ads:\n\n1. Check that you've set up a Publisher Campaign on the Chartboost dashboard.\n2. From the Chartoost dashboard, enable Test Mode by selecting your app in the sidebar > App Settings > Basic Settings > set \"Test Mode\" to \"Enabled\".";
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable
{
    return [HZChartboost hzProxiedClassIsAvailable];
}

- (NSError *)internalInitializeSDK {
    if (![self hasNecessaryCredentials]) {
        NSMutableArray *erroredCredentials = [NSMutableArray array];
        if (!self.appID){
            [erroredCredentials addObject:@"App ID"];
        }
        
        if (!self.appSignature) {
            [erroredCredentials addObject:@"App Signature"];
        }
        
        RETURN_ERROR_UNLESS(NO, ([NSString stringWithFormat:@"%@ needs an App ID and an App Signature set up on your dashboard, you're missing these: [%@]", [self humanizedName], [erroredCredentials componentsJoinedByString:@", "]]));
    }
    
    if ([HZChartboost respondsToSelector:@selector(setMediation:withVersion:)]) {
        NSMethodSignature *signature = [HZChartboost methodSignatureForSelector:@selector(setMediation:withVersion:)];
        if (signature) {
            NSString *const type = [NSString stringWithUTF8String:[signature getArgumentTypeAtIndex:2]]; // See docs: "The hidden arguments self (of type id) and _cmd (of type SEL) are at indices 0 and 1; method-specific arguments begin at index 2."
            if ([type isEqualToString:@"@"]) { // @ for objects
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
                [HZChartboost setMediation:@"HeyZap" withVersion:SDK_VERSION]; // Chartboost < 6
#pragma clang diagnostic pop
            } else {
                [HZChartboost setMediation:CBMediationHeyZap withVersion:SDK_VERSION]; // Chartboost >= 6
            }
        } else {
            HZELog(@"Couldn't create the method signature for setMediation:withVersion: for Chartboost. This means we can't tell Chartboost that we're mediating them, which they use for analytics/diagnostic purposes. Please report this to support@heyzap.com.");
        }
    }
    
    [HZChartboost startWithAppId:self.appID appSignature:self.appSignature delegate:self.forwardingDelegate];
    [HZChartboost setShouldPrefetchVideoContent:YES];
    
    return nil;
}

+ (NSString *)name
{
    return HZNetworkChartboost;
}

+ (NSString *)humanizedName
{
    return kHZAdapterChartboostHumanized;
}

+ (NSString *)sdkVersion {
    return nil; // Chartboost doesn't provide the version.
}

NSString * const kHZCBLocationDefault = @"Default";

- (void)internalPrefetchAdWithOptions:(HZAdapterFetchOptions *)options
{
    switch (options.creativeType) {
        case HZCreativeTypeStatic:
            [HZChartboost cacheInterstitial:kHZCBLocationDefault];
            break;
        case HZCreativeTypeIncentivized:
            [HZChartboost cacheRewardedVideo:kHZCBLocationDefault];
            break;
        case HZCreativeTypeBanner:
        case HZCreativeTypeNative:
        case HZCreativeTypeVideo:
        case HZCreativeTypeUnknown: {
            // Unsupported
        }
    }
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    switch (dataProvider.creativeType) {
        case HZCreativeTypeIncentivized:
            return [HZChartboost hasRewardedVideo:kHZCBLocationDefault];
        case HZCreativeTypeStatic:
            return [HZChartboost hasInterstitial:kHZCBLocationDefault];
        default:
            return NO;
    }
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options
{
    switch (options.creativeType) {
        case HZCreativeTypeStatic:
            [HZChartboost showInterstitial:kHZCBLocationDefault];
            break;
        case HZCreativeTypeIncentivized:
            [HZChartboost showRewardedVideo:kHZCBLocationDefault];
            break;
        default:
            // Unsupported
            break;
    }
}

- (HZCreativeType) supportedCreativeTypes
{
    // We don't currently have a way to tell if an interstitial from Chartboost is a static or video ad.
    // Until we do, we will treat them as all static.
    return HZCreativeTypeStatic | HZCreativeTypeIncentivized;
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
    [self setLastFetchError:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey: @"Chartboost"}] forAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeStatic]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location
                         withError:(CBLoadError)error {
    [[self class] logError:error];
    [self setLastFetchError:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey:@"Chartboost"}] forAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeIncentivized]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
    [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeIncentivized]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void)didClickRewardedVideo:(CBLocation)location {
    [self.delegate adapterWasClicked: self];
}

- (void)didClickInterstitial:(CBLocation)location
{
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
    [self maybeFinishPlayingAudio];
    [self.delegate adapterDidDismissAd:self];
}

// Called before an interstitial will be displayed on the screen.
- (BOOL)shouldDisplayInterstitial:(CBLocation)location {
    return YES;
}

// Called after an interstitial has been displayed on the screen.
- (void)didDisplayInterstitial:(CBLocation)location {
    [self.delegate adapterDidShowAd:self];
}

- (void)didDisplayRewardedVideo:(CBLocation)location {
    [self.delegate adapterDidShowAd:self];
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
    [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:HZCreativeTypeStatic]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
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
    [self maybeFinishPlayingAudio];
    [self.delegate adapterDidDismissAd:self];
}

/**
 *  More Apps
 */
- (void)didFailToLoadMoreApps:(CBLocation)location withError:(CBLoadError)error {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackChartboostMoreAppsFetchFailed forNetwork: [self name]];
}

- (void)didCacheMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackChartboostMoreAppsAvailable forNetwork: [self name]];
}

- (void)didDismissMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackChartboostMoreAppsDismiss forNetwork: [self name]];
}

- (void)didCloseMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackChartboostMoreAppsHide forNetwork: [self name]];
}

- (void)didClickMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackChartboostMoreAppsClick forNetwork: [self name]];
}

- (void)didDisplayMoreApps:(CBLocation)location {
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackChartboostMoreAppsShow forNetwork: [self name]];
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
            HZELog(@"Chartboost: Failed to load Interstitial, no Internet connection !");
        } break;
        case CBLoadErrorInternal: {
            HZELog(@"Chartboost: Failed to load Interstitial, internal error !");
        } break;
        case CBLoadErrorNetworkFailure: {
            HZELog(@"Chartboost: Failed to load Interstitial, network error !");
        } break;
        case CBLoadErrorWrongOrientation: {
            HZELog(@"Chartboost: Failed to load Interstitial, wrong orientation !");
        } break;
        case CBLoadErrorTooManyConnections: {
            HZELog(@"Chartboost: Failed to load Interstitial, too many connections !");
        } break;
        case CBLoadErrorFirstSessionInterstitialsDisabled: {
            HZELog(@"Chartboost: Failed to load Interstitial, first session !");
        } break;
        case CBLoadErrorNoAdFound : {
            HZELog(@"Chartboost: Failed to load Interstitial, no ad found !");
        } break;
        case CBLoadErrorSessionNotStarted : {
            HZELog(@"Chartboost: Failed to load Interstitial, session not started !");
        } break;
        default: {
            HZELog(@"Chartboost: Failed to load Interstitial, unknown error !");
        }
    }
}

- (void)maybeFinishPlayingAudio {
    if (self.isPlayingAudio) {
        [self.delegate adapterDidFinishPlayingAudio:self];
    }
    self.isPlayingAudio = NO;
}

- (void)willDisplayVideo:(CBLocation)location {
    self.isPlayingAudio = YES;
    [self.delegate adapterWillPlayAudio:self];
}

@end
