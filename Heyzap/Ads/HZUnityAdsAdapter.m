//
//  HZUnityAdsAdapter.m
//  Heyzap
//
//  Created by David Stumm on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZUnityAdsAdapter.h"
#import "HZUnityAds.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZMetrics.h"
#import "HZMetricsAdStub.h"
#import "HZUnityAbstractAdapter.h"

@interface HZUnityAdsAdapter() <HZUnityAdsDelegate>

@property (nonatomic, strong) NSString *videoZoneID;
@property (nonatomic, strong) NSString *incentivizedZoneID;
@property (nonatomic) BOOL isShowingIncentivized;
@property (nonatomic) BOOL didSkipIncentivized;

@end

@implementation HZUnityAdsAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZUnityAdsAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZUnityAdsAdapter alloc] init];
    });
    return proxy;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.forwardingDelegate = [HZAdapterDelegate new];
        self.forwardingDelegate.adapter = self;
        [[HZUnityAds sharedInstance] setDelegate:self.forwardingDelegate];
    }
    return self;
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable
{
    return [HZUnityAds hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return kHZAdapterUnityAds;
}

+ (NSString *) humanizedName
{
    return kHZAdapterUnityAdsHumanized;
}

- (HZNetwork)network {
    return HZNetworkUnityAds;
}

+ (NSString *)sdkVersion
{
    return [HZUnityAds getSDKVersion];
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    NSParameterAssert(credentials);
    NSError *error;
    NSString *appID = [HZDictionaryUtils objectForKey:@"game_id"
                                              ofClass:[NSString class]
                                                 dict:credentials
                                                error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *incentivizedZoneID = [HZDictionaryUtils objectForKey:@"incentivized_placement_id"
                                                                 ofClass:[NSString class]
                                                                    dict:credentials
                                                                   error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *videoZoneID = [HZDictionaryUtils objectForKey:@"video_placement_id"
                                                          ofClass:[NSString class]
                                                             dict:credentials
                                                            error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    HZUnityAdsAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        [[self sharedInstance] setupUnityAdsWithAppID:appID
                                          videoZoneID:videoZoneID incentivizedZoneID:incentivizedZoneID];
    }
    
    return nil;
}

NSString * const kHZNetworkName = @"mobile";

- (void)setupUnityAdsWithAppID:(NSString *)appID
                    videoZoneID:(NSString *)videoZoneID
             incentivizedZoneID:(NSString *)incentivizedZoneID
{
    NSParameterAssert(appID);
    NSParameterAssert(videoZoneID);
    NSParameterAssert(incentivizedZoneID);
    self.videoZoneID = videoZoneID;
    self.incentivizedZoneID = incentivizedZoneID;
    
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if ([[HZUnityAds sharedInstance] respondsToSelector:@selector(setNetworks:)]) { // Asset Store version
        [[HZUnityAds sharedInstance] setNetworks:kHZNetworkName];
    }
    [[HZUnityAds sharedInstance] startWithGameId:appID andViewController:vc];
    
    //TODO: set view controller
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return YES;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (![[[UIApplication sharedApplication] keyWindow] rootViewController]) {
        // This is important so we should always NSLog this.
        NSLog(@"UnityAds reqires a root view controller on the keyWindow to show ads. Make sure [[[UIApplication sharedApplication] keyWindow] rootViewController] does not return `nil`.");
        return NO;
    }
    
    if ([[HZUnityAds sharedInstance] respondsToSelector:@selector(canShowAds)]) { // Regular SDK
        return [[HZUnityAds sharedInstance] canShowAds];
    } else if ([[HZUnityAds sharedInstance] respondsToSelector:@selector(canShowAds:)]) { // Asset Store version
        [[HZUnityAds sharedInstance] setNetwork:kHZNetworkName];
        return [[HZUnityAds sharedInstance] canShowAds:kHZNetworkName];
    } else {
        @throw [NSException exceptionWithName:@"UnsupportedSDKException" reason:@"This version of UnityAds doesn't respond to canShowAds or canShowAds:(NSString *)network and is not compatible with the Heyzap SDK." userInfo:nil];
    }
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // AdColony auto-prefetches
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    [[HZUnityAds sharedInstance] setViewController:options.viewController];
    if (type == HZAdTypeIncentivized) {
        self.isShowingIncentivized = YES;
        [[HZUnityAds sharedInstance] setZone:self.incentivizedZoneID];
    } else {
        self.isShowingIncentivized = NO;
        [[HZUnityAds sharedInstance] setZone:self.videoZoneID];
    }
    [[HZUnityAds sharedInstance] show];

    self.metricsStub = [[HZMetricsAdStub alloc] initWithTag:options.tag adUnit:NSStringFromAdType(type)];
    [[HZMetrics sharedInstance] logTimeSinceShowAdFor:kShowAdTimeTillAdIsDisplayedKey withProvider:self.metricsStub network:[self name]];
}

#pragma mark - AdColony Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"UnityAdsDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)unityAdsVideoCompleted:(NSString *)rewardItemKey skipped:(BOOL)skipped {
    [self.delegate adapterDidFinishPlayingAudio:self];
    self.didSkipIncentivized = skipped;
}

- (void)unityAdsDidHide {
    if (self.isShowingIncentivized) {
        if (self.didSkipIncentivized) {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
            [HZUnityAbstractAdapter sendMessage:@"incentivized_result_incomplete" fromNetwork:kHZAdapterUnityAds];
        } else {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
            [HZUnityAbstractAdapter sendMessage:@"incentivized_result_complete" fromNetwork:kHZAdapterUnityAds];
        }
    }
    self.isShowingIncentivized = NO;
    self.didSkipIncentivized = NO;
    [self.delegate adapterDidDismissAd:self];
    [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [HZUnityAbstractAdapter sendMessage:@"hide" fromNetwork:kHZAdapterUnityAds];
}

- (void)unityAdsWillLeaveApplication {
    [[HZMetrics sharedInstance] logMetricsEvent:kAdClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterWasClicked:self];
    [HZUnityAbstractAdapter sendMessage:@"click" fromNetwork:kHZAdapterUnityAds];
}

- (void)unityAdsVideoStarted {
    [self.delegate adapterWillPlayAudio:self];
    [HZUnityAbstractAdapter sendMessage:@"audio_starting" fromNetwork:kHZAdapterUnityAds];
}

@end
