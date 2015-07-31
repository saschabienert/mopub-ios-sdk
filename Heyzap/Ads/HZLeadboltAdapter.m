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

@interface HZLeadboltAdapter()

@property (nonatomic) BOOL interstitialCached;
@property (nonatomic) BOOL incentivizedCached;

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

+ (instancetype)sharedInstance
{
    static HZLeadboltAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZLeadboltAdapter alloc] init];
    });
    return adapter;
}

#pragma mark - Adapter Protocol

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    HZParameterAssert(credentials);
    
    NSError *error;
    NSString *const appAPIKey = [HZDictionaryUtils objectForKey:@"app_api_key" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    
    HZLeadboltAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        [[self sharedInstance] setupLeadboltWithAppAPIKey:appAPIKey];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    }
    
    return nil;
}

- (void)setupLeadboltWithAppAPIKey:(NSString *const)appAPIKey
{
    // These notifications aren't documented in AppTracker.h; this comes from http://help.leadbolt.com/ios-integration-guide/ and their sample app.
    
    NSNotificationCenter *const nc = [NSNotificationCenter defaultCenter];
    NSString *const object = @"AppFireworksNotification";
    [nc addObserver:self selector:@selector(onModuleLoaded:)  name:@"onModuleLoaded"  object:object];
    [nc addObserver:self selector:@selector(onModuleFailed:)  name:@"onModuleFailed"  object:object];
    [nc addObserver:self selector:@selector(onModuleCached:)  name:@"onModuleCached"  object:object];
    [nc addObserver:self selector:@selector(onModuleClosed:)  name:@"onModuleClosed"  object:object];
    [nc addObserver:self selector:@selector(onModuleClicked:) name:@"onModuleClicked" object:object];
    [nc addObserver:self selector:@selector(onMediaFinished:) name:@"onMediaFinished" object:object];
    
    [HZAppTracker startSession:appAPIKey]; // NB: Leadbolt must be started after registering for NSNotifications per docs.
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackInitialized forNetwork:[self name]];
}

+ (BOOL)isSDKAvailable
{
    return [HZAppTracker hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return @"leadbolt";
}


+ (NSString *)humanizedName {
    return @"Leadbolt";
}

+ (NSString *)sdkVersion
{
    return nil;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork
{
    return NO;
}

- (void)prefetchForType:(HZAdType)type
{
    HZDLog(@"Prefetching Leadbolt ad of type: %@",NSStringFromAdType(type));
    switch (type) {
        case HZAdTypeInterstitial: {
            [HZAppTracker loadModuleToCache:kHZLeadboltInterstitialModule];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZAppTracker loadModuleToCache:kHZLeadboltIncentivizedModule];
            break;
        }
        case HZAdTypeVideo:
        case HZAdTypeBanner: {
            // Unsupported
            break;
        }
    }
}

- (BOOL)hasAdForType:(HZAdType)type
{
    switch (type) {
        case HZAdTypeInterstitial: {
            return self.interstitialCached;
        }
        case HZAdTypeIncentivized: {
            return self.incentivizedCached;
        }
        case HZAdTypeVideo:
        case HZAdTypeBanner: {
            return NO;
        }
    }
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    HZDLog(@"Requesting that Leadbolt show an ad of type: %@",NSStringFromAdType(type));
    switch (type) {
        case HZAdTypeInterstitial: {
            self.interstitialCached = NO;
            [HZAppTracker loadModule:kHZLeadboltInterstitialModule viewController:options.viewController];
            break;
        }
        case HZAdTypeIncentivized: {
            self.incentivizedCached = NO;
            [HZAppTracker loadModule:kHZLeadboltIncentivizedModule viewController:options.viewController];
            break;
        }
        case HZAdTypeVideo:
        case HZAdTypeBanner: {
            // Ignored
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
    } else { // Otherwise, it failed to show
        HZELog(@"Mediation: Leadbolt ad failed to display; notification = %@", notification);
        [self.delegate adapterDidFailToShowAd:self error:nil];
    }
}

- (void)onModuleCached:(NSNotification *)notification {
    [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackAvailable forNetwork:[self name]];
    HZDLog(@"Leadbolt ad cached; notification = %@",notification);
    NSString *const placement = notification.userInfo[@"placement"];
    
    if ([placement isEqualToString:kHZLeadboltInterstitialModule]) {
        self.interstitialCached = YES;
    } else if ([placement isEqualToString:kHZLeadboltIncentivizedModule]) {
        self.incentivizedCached = YES;
    } else {
        HZELog(@"Unknown module cached by Leadbolt. This shouldn't break anything, but it's unexpected. notification = %@",notification);
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

@end
