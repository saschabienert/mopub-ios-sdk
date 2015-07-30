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
#import "HeyzapMediation.h"

@interface HZUnityAdsAdapter() <HZUnityAdsDelegate>

@property (nonatomic, strong) NSString *videoZoneID;
@property (nonatomic, strong) NSString *incentivizedZoneID;
@property (nonatomic) BOOL isShowingIncentivized;
@property (nonatomic) BOOL didCompleteIncentivized;

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
    return HZNetworkUnityAds;
}

+ (NSString *) humanizedName
{
    return kHZAdapterUnityAdsHumanized;
}

+ (NSString *)sdkVersion
{
    return [HZUnityAds getSDKVersion];
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    HZParameterAssert(credentials);
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
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    }
    
    return nil;
}

NSString * const kHZNetworkName = @"mobile";

- (void)setupUnityAdsWithAppID:(NSString *)appID
                    videoZoneID:(NSString *)videoZoneID
             incentivizedZoneID:(NSString *)incentivizedZoneID
{
    HZParameterAssert(appID);
    HZParameterAssert(videoZoneID);
    HZParameterAssert(incentivizedZoneID);
    self.videoZoneID = videoZoneID;
    self.incentivizedZoneID = incentivizedZoneID;
    
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if ([[HZUnityAds sharedInstance] respondsToSelector:@selector(setNetworks:)]) { // Asset Store version
        [[HZUnityAds sharedInstance] setNetworks:kHZNetworkName];
    }
    [[HZUnityAds sharedInstance] startWithGameId:appID andViewController:vc];
    [[HZUnityAds sharedInstance] setDelegate:self.forwardingDelegate];
    
    //TODO: set view controller
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return YES;
}

- (BOOL)hasAdForType:(HZAdType)type
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

- (void)prefetchForType:(HZAdType)type
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

    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackShow forNetwork: [self name]];
}

+ (NSTimeInterval)isAvailablePollInterval {
    // UnityAds uses expensive I/O operations to check if an ad is available.
    return 3;
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

- (void)unityAdsDidShow {
    [self.delegate adapterDidShowAd:self];
}

/**
 * Note: There is a bug associated with the callback: When the app is moved to
 * the background during an incentivized ad play, this callback is not fired.
 */
- (void)unityAdsVideoCompleted:(NSString *)rewardItemKey skipped:(BOOL)skipped {
    [self.delegate adapterDidFinishPlayingAudio:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioFinished forNetwork: [self name]];
    self.didCompleteIncentivized = !skipped;
}

- (void)unityAdsDidHide {
    if (self.isShowingIncentivized) {
        if (self.didCompleteIncentivized) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
            
            [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultComplete forNetwork: [self name]];
            
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
            
            [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultIncomplete forNetwork: [self name]];
        }
    }
    self.isShowingIncentivized = NO;
    self.didCompleteIncentivized = NO;
    [self.delegate adapterDidDismissAd:self];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackHide forNetwork: [self name]];
}

- (void)unityAdsWillLeaveApplication {
    [self.delegate adapterWasClicked:self];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self name]];
}

- (void)unityAdsVideoStarted {
    [self.delegate adapterWillPlayAudio:self];
    
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioStarting forNetwork: [self name]];
}

@end
