//
//  HZVungleProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZVungleAdapter.h"
#import <UIKit/UIKit.h>
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZVungleSDK.h"
#import "HZUtils.h"
#import "HeyzapMediation.h"

@interface HZVungleAdapter() <HZVungleSDKDelegate>

/**
 *  Because Vungle makes no differentiation between having an incentivized ad and having a video ad, we just store any error in a property shared between the ad types.
 */
@property (nonatomic, strong) NSError *lastError;
@property (nonatomic) BOOL isShowingIncentivized;

@end

@implementation HZVungleAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZVungleAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZVungleAdapter alloc] init];
    });
    return proxy;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.forwardingDelegate = [HZAdapterDelegate new];
        self.forwardingDelegate.adapter = self;
    }
    return self;
}

#pragma mark - Adapter Protocol

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    HZParameterAssert(credentials);
    NSError *error;
    NSString *appID = [HZDictionaryUtils objectForKey:@"app_id" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    HZVungleAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        [[self sharedInstance] startWithPubAppID:appID];
        [[HZVungleSDK sharedSDK] setDelegate:adapter.forwardingDelegate];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    }
    
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZVungleSDK hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return HZNetworkVungle;
}

+ (NSString *)humanizedName
{
    return kHZAdapterVungleHumanized;
}

+ (NSString *)sdkVersion {
    return hzLookupStringConstant(@"VungleSDKVersion");
}

- (void)startWithPubAppID:(NSString *)appID
{
    [[HZVungleSDK sharedSDK] startWithAppId:appID];
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeIncentivized | HZAdTypeVideo;
}

- (BOOL)isVideoOnlyNetwork {
    return YES;
}

- (void)prefetchForType:(HZAdType)type
{
    // Vungle autoprefetches, and incentivized == regular video on their platform.
}

- (BOOL)hasAdForType:(HZAdType)type
{
    BOOL adPlayable = NO;
    
    // in v.3.1.0 `isAdPlayable` is added, `isCachedAdAvailable` is deprecated
    if ([[HZVungleSDK sharedSDK] respondsToSelector:@selector(isAdPlayable)]) {
        adPlayable = [[HZVungleSDK sharedSDK] isAdPlayable];
        
    } else {
        adPlayable = [[HZVungleSDK sharedSDK] isCachedAdAvailable];
    }
    
    return [self supportedAdFormats] & type && adPlayable;
}

- (NSError *)lastErrorForAdType:(HZAdType)adType
{
    return self.lastError;
}

- (void)clearErrorForAdType:(HZAdType)adType
{
    self.lastError = nil;
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    // setup options
    NSMutableDictionary *vungleOptions = [[NSMutableDictionary alloc] init];
    
    if (type == HZAdTypeIncentivized) {
        self.isShowingIncentivized = YES;
        
        NSString *const incentivizedKey = [[self class] vunglePlayAdOptionKeyIncentivized];
        vungleOptions[incentivizedKey] = @1;
    }
    
    NSError *error;
    [[HZVungleSDK sharedSDK] playAd:options.viewController withOptions:vungleOptions error:&error];
    
    if (error) {
        [self.delegate adapterDidFailToShowAd:self error:error];
    }
}

#pragma mark - Vungle Delegate

/* Note: There is a bug with the Vungle SDK. `willPresentProductSheet` method gets called first and then the `vungleSDKwillCloseAdWithViewInfo` method, even though their docs state the opposite order. This made us end up calling `adapterDidDismissAd` in `willPresentProductSheet` FIRST, which prevented any further callbacks for the session to be called (i.e. the `did*CompleteAdWithTag` for incentivized ads to be called).
 * Please git blame and revert changes to the two callbacks when the bug is resolved.
 */

- (void)vungleSDKwillShowAd {
    [self.delegate adapterDidShowAd:self];
    [self.delegate adapterWillPlayAudio:self]; // adapterWillPlayAudio has to be called AFTER adapterDidShowAd
}

- (void)vungleSDKwillCloseAdWithViewInfo:(NSDictionary*)viewInfo willPresentProductSheet:(BOOL)willPresentProductSheet
{
    if (self.isShowingIncentivized) {
        if ([viewInfo[@"completedView"] boolValue]) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
            
            [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultComplete forNetwork: [self name]];
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
            
            [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultIncomplete forNetwork: [self name]];
        }
    }
    
    if ([viewInfo[@"didDownload"] boolValue]) {
        [self.delegate adapterWasClicked:self];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self name]];
    }
    
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackDismiss forNetwork: [self name]];
    
    self.isShowingIncentivized = NO;
}

- (void)vungleSDKwillCloseProductSheet:(id)productSheet {
    
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"VungleSDKDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

+ (NSString *)vunglePlayAdOptionKeyIncentivized {
    return @"incentivized";
}

@end
