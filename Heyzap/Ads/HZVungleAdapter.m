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
#import "HZMetrics.h"
#import "HZMetricsAdStub.h"

const NSString* HZVunglePlayAdOptionKeyIncentivized        = @"incentivized";
const NSString* HZVunglePlayAdOptionKeyShowClose           = @"showClose";
const NSString* HZVunglePlayAdOptionKeyOrientations        = @"orientations";
const NSString* HZVunglePlayAdOptionKeyUser                = @"user";
const NSString* HZVunglePlayAdOptionKeyPlacement           = @"placement";
const NSString* HZVunglePlayAdOptionKeyExtraInfoDictionary = @"extraInfo";
const NSString* HZVunglePlayAdOptionKeyExtra1              = @"extra1";
const NSString* HZVunglePlayAdOptionKeyExtra2              = @"extra2";
const NSString* HZVunglePlayAdOptionKeyExtra3              = @"extra3";
const NSString* HZVunglePlayAdOptionKeyExtra4              = @"extra4";
const NSString* HZVunglePlayAdOptionKeyExtra5              = @"extra5";
const NSString* HZVunglePlayAdOptionKeyExtra6              = @"extra6";
const NSString* HZVunglePlayAdOptionKeyExtra7              = @"extra7";
const NSString* HZVunglePlayAdOptionKeyExtra8              = @"extra8";
const NSString* HZVunglePlayAdOptionKeyLargeButtons        = @"largeButtons";

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
        [[HZVungleSDK sharedSDK] setDelegate:self];
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
    }
    
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZVungleSDK hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return kHZAdapterVungle;
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

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // Vungle autoprefetches, and incentivized == regular video on their platform.
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    return [self supportedAdFormats] & type && [[HZVungleSDK sharedSDK] isCachedAdAvailable];
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
    [self.delegate adapterWillPlayAudio:self];
    
    if (type == HZAdTypeIncentivized) {
        self.isShowingIncentivized = YES;
        [[HZVungleSDK sharedSDK] playAd:options.viewController withOptions:@{HZVunglePlayAdOptionKeyIncentivized: @1}];
    } else {
        [[HZVungleSDK sharedSDK] playAd:options.viewController withOptions:@{HZVunglePlayAdOptionKeyShowClose: @1}];
    }

    self.metricsStub = [[HZMetricsAdStub alloc] initWithTag:options.tag adUnit:NSStringFromAdType(type)];
    [[HZMetrics sharedInstance] logTimeSinceShowAdFor:kShowAdTimeTillAdIsDisplayedKey withProvider:self.metricsStub network:[self name]];
}

#pragma mark - Vungle Delegate

- (void)vungleSDKwillCloseAdWithViewInfo:(NSDictionary*)viewInfo willPresentProductSheet:(BOOL)willPresentProductSheet
{
    if (self.isShowingIncentivized) {
        if ([viewInfo[@"completedView"] boolValue]) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
    
    if (willPresentProductSheet) {
        [[HZMetrics sharedInstance] logMetricsEvent:kAdClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
        [self.delegate adapterWasClicked:self];
    } else {
        [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
        [self.delegate adapterDidFinishPlayingAudio:self];
        [self.delegate adapterDidDismissAd:self];
    }
    
    self.isShowingIncentivized = NO;
}

- (void)vungleSDKwillCloseProductSheet:(id)productSheet
{
    [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"VungleSDKDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

@end
