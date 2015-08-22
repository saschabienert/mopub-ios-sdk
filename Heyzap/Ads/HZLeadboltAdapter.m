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

- (void)loadCredentials {
    self.appAPIKey = [HZDictionaryUtils objectForKey:@"app_api_key"
                                             ofClass:[NSString class]
                                                dict:self.credentials];
}

- (NSError *)initializeSDK {
    RETURN_ERROR_IF_NIL(self.appAPIKey, @"app_api_key");
    
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
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback:HZNetworkCallbackInitialized forNetwork:[self name]];
    
    return nil;
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

- (HZCreativeType)supportedCreativeTypes
{
    // We don't currently have a way to tell if an interstitial from Leadbolt is a static or video ad.
    // Until we do, we will treat them as all static.
    return HZCreativeTypeStatic | HZCreativeTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork
{
    return NO;
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            HZDLog(@"Prefetching Leadbolt ad of type: %@",NSStringFromCreativeType(creativeType));
            [HZAppTracker loadModuleToCache:kHZLeadboltInterstitialModule];
            break;
        }
        case HZCreativeTypeIncentivized: {
            HZDLog(@"Prefetching Leadbolt ad of type: %@",NSStringFromCreativeType(creativeType));
            [HZAppTracker loadModuleToCache:kHZLeadboltIncentivizedModule];
            break;
        }
        default: {
            // Unsupported
            HZDLog(@"Can't prefetch Leadbolt ad of unsupported type: %@",NSStringFromCreativeType(creativeType));
            break;
        }
    }
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    switch (creativeType) {
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

- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    HZDLog(@"Requesting that Leadbolt show an ad of type: %@",NSStringFromCreativeType(creativeType));
    switch (creativeType) {
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
            HZDLog(@"Can't show Leadbolt ad of unsupported type: %@",NSStringFromCreativeType(creativeType));
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
        self.staticCached = YES;
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
