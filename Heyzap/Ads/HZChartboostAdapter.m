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
        [HZChartboost sharedChartboost].delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
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
    NSString *const appID = [HZDictionaryUtils objectForKey:@"app_id" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *const appSignature = [HZDictionaryUtils objectForKey:@"app_signature" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    [[self sharedInstance] setupChartboostWithAppID:appID appSignature:appSignature];
    
    return nil;
}

+ (NSString *)name
{
    return kHZAdapterChartboost;
}

- (void)setupChartboostWithAppID:(NSString *)appID appSignature:(NSString *)appSignature
{
    [[HZChartboost sharedChartboost] setAppId:appID];
    [[HZChartboost sharedChartboost] setAppSignature:appSignature];
    
    [[HZChartboost sharedChartboost] startSession];
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // Chartboost has tag support, but we're going to use it for geos
    [[HZChartboost sharedChartboost] cacheInterstitial:[self.delegate countryCode]];
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    return ([self supportedAdFormats] & type) && [[HZChartboost sharedChartboost] hasCachedInterstitial:[self.delegate countryCode]];
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    [[HZChartboost sharedChartboost] showInterstitial:[self.delegate countryCode]];
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial;
}

#pragma mark - NSNotifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Chartboost requires this to be called each time the app becomes active.
    [[HZChartboost sharedChartboost] startSession];
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
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey: @"Chartboost"}];
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

- (void)didClickInterstitial:(NSString *)location
{
    [self.delegate adapterWasClicked:self];
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

- (void)didCacheInterstitial:(NSString *)location {
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

- (void)didDismissInterstitial:(NSString *)location {
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


@end