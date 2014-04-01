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

@interface HZChartboostAdapter()

@end

@implementation HZChartboostAdapter

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

+ (instancetype)sharedInstance
{
    static HZChartboostAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZChartboostAdapter alloc] init];
    });
    return proxy;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"Chartboost class proxy used");
        [HZChartboost sharedChartboost].delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)setupChartboostWithAppID:(NSString *)appID appSignature:(NSString *)appSignature
{
    [[HZChartboost sharedChartboost] setAppId:appID];
    [[HZChartboost sharedChartboost] setAppSignature:appSignature];
    
    [[HZChartboost sharedChartboost] startSession];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Chartboost requires this to be called each time the app becomes active.
    [[HZChartboost sharedChartboost] startSession];
}

#pragma mark - Protocol Implementation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"ChartboostDelegate"]) {
        NSLog(@"Conforms to protocol called on chartboost delegate");
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)prefetch
{
    [[HZChartboost sharedChartboost] cacheInterstitial];
}

- (BOOL)hasAd
{
    return [[HZChartboost sharedChartboost] hasCachedInterstitial];
}

- (void)showAd
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
    [[HZChartboost sharedChartboost] showInterstitial];
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial;
}

#pragma mark - Chartboost Delegate callbacks

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

- (void)didFailToLoadInterstitial:(NSString *)location withError:(HZCBLoadError)error {
    self.lastError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey: @"Charboost"}];
//    switch(error){
//        case CBLoadErrorInternetUnavailable: {
//            NSLog(@"Failed to load Interstitial, no Internet connection !");
//        } break;
//        case CBLoadErrorInternal: {
//            NSLog(@"Failed to load Interstitial, internal error !");
//        } break;
//        case CBLoadErrorNetworkFailure: {
//            NSLog(@"Failed to load Interstitial, network error !");
//        } break;
//        case CBLoadErrorWrongOrientation: {
//            NSLog(@"Failed to load Interstitial, wrong orientation !");
//        } break;
//        case CBLoadErrorTooManyConnections: {
//            NSLog(@"Failed to load Interstitial, too many connections !");
//        } break;
//        case CBLoadErrorFirstSessionInterstitialsDisabled: {
//            NSLog(@"Failed to load Interstitial, first session !");
//        } break;
//        case CBLoadErrorNoAdFound : {
//            NSLog(@"Failed to load Interstitial, no ad found !");
//        } break;
//        case CBLoadErrorSessionNotStarted : {
//            NSLog(@"Failed to load Interstitial, session not started !");
//        } break;
//        default: {
//            NSLog(@"Failed to load Interstitial, unknown error !");
//        }
//    }
}

- (void)didClickInterstitial:(NSString *)location
{
    NSLog(@"Chartboost ad was clicked");
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
    self.lastError = nil;
    NSLog(@"Chartboost interstitial cached at location %@", location);
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
    NSLog(@"dismissed interstitial at location %@", location);
//    [[Chartboost sharedChartboost] cacheInterstitial:location];
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
