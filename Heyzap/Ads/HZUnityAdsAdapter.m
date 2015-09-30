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
#import "HZBaseAdapter_Internal.h"

@interface HZUnityAdsAdapter() <HZUnityAdsDelegate>

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *videoZoneID;
@property (nonatomic, strong) NSString *incentivizedZoneID;
@property (nonatomic) BOOL isShowingIncentivized;
@property (nonatomic) BOOL didCompleteIncentivized;

@end

@implementation HZUnityAdsAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
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

- (void)loadCredentials {
    self.appID = [HZDictionaryUtils objectForKey:@"game_id"
                                         ofClass:[NSString class]
                                            dict:self.credentials];
    
    self.incentivizedZoneID = [HZDictionaryUtils objectForKey:@"incentivized_placement_id"
                                                      ofClass:[NSString class]
                                                         dict:self.credentials];
    
    self.videoZoneID = [HZDictionaryUtils objectForKey:@"video_placement_id"
                                               ofClass:[NSString class]
                                                  dict:self.credentials];
}

- (void) toggleLogging {
    [[HZUnityAds sharedInstance] setDebugMode:[self isLoggingEnabled]];
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

NSString * const kHZNetworkName = @"mobile";

- (NSError *)internalInitializeSDK {
    RETURN_ERROR_IF_NIL(self.appID, @"game_id");
    
    [self toggleLogging];
    
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if ([[HZUnityAds sharedInstance] respondsToSelector:@selector(setNetworks:)]) { // Asset Store version
        [[HZUnityAds sharedInstance] setNetworks:kHZNetworkName];
    }
    HZDLog(@"Initializing UnityAds with Game ID: %@",self.appID);
    [[HZUnityAds sharedInstance] startWithGameId:self.appID andViewController:vc];
    [[HZUnityAds sharedInstance] setDelegate:self.forwardingDelegate];
    
    return nil;
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeVideo | HZCreativeTypeIncentivized;
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    if(![self supportsCreativeType:creativeType]) return NO;
    
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

- (BOOL)hasCredentialsForCreativeType:(HZCreativeType)creativeType {
    switch (creativeType) {
        case HZCreativeTypeIncentivized: {
            return self.incentivizedZoneID != nil;
        }
        case HZCreativeTypeVideo: {
            return self.videoZoneID != nil;
        }
        default: {
            return NO;
        }
    }
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    // UnityAds auto-prefetches
}

- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    [[HZUnityAds sharedInstance] setViewController:options.viewController];
    if (creativeType == HZCreativeTypeIncentivized) {
        self.isShowingIncentivized = YES;
        [[HZUnityAds sharedInstance] setZone:self.incentivizedZoneID];
    } else {
        self.isShowingIncentivized = NO;
        [[HZUnityAds sharedInstance] setZone:self.videoZoneID];
    }
    [[HZUnityAds sharedInstance] show];
}

+ (NSTimeInterval)isAvailablePollInterval {
    // UnityAds uses expensive I/O operations to check if an ad is available.
    return 3;
}
#pragma mark - UnityAds Delegation

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
    self.didCompleteIncentivized = !skipped;
}

- (void)unityAdsDidHide {
    if (self.isShowingIncentivized) {
        if (self.didCompleteIncentivized) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
            
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
    self.isShowingIncentivized = NO;
    self.didCompleteIncentivized = NO;
    [self.delegate adapterDidDismissAd:self];
}

- (void)unityAdsWillLeaveApplication {
    [self.delegate adapterWasClicked:self];
}

- (void)unityAdsVideoStarted {
    [self.delegate adapterWillPlayAudio:self];
}

@end
