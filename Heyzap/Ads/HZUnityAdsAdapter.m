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

@interface HZUnityAdsAdapter() <HZUnityAdsDelegate>

@property (nonatomic, strong) NSString *videoZoneID;
@property (nonatomic, strong) NSString *incentivizedZoneID;
@property (nonatomic) BOOL isShowingIncentivized;

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
        [[HZUnityAds sharedInstance] setDelegate:self];
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

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    NSParameterAssert(credentials);
    NSError *error;
    NSString *appID = [HZDictionaryUtils objectForKey:@"game_id"
                                              ofClass:[NSString class]
                                                 dict:credentials
                                                error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *const incentivizedZoneID = [HZDictionaryUtils objectForKey:@"incentivized_placement_id"
                                                                 ofClass:[NSString class]
                                                                    dict:credentials
                                                                   error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    NSString *const videoZoneID = [HZDictionaryUtils objectForKey:@"video_placement_id"
                                                          ofClass:[NSString class]
                                                             dict:credentials
                                                            error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    
    
    [[self sharedInstance] setupUnityAdsWithAppID:appID
                                     videoZoneID:videoZoneID incentivizedZoneID:incentivizedZoneID];
    
    return nil;
}

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
    
    [[HZUnityAds sharedInstance] startWithGameId:appID andViewController:vc];
    
    //TODO: set view controller
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeVideo | HZAdTypeIncentivized;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (![[[UIApplication sharedApplication] keyWindow] rootViewController]) {
        // This is important so we should always NSLog this.
        NSLog(@"UnityAds reqires a root view controller on the keyWindow to show ads. Make sure [[[UIApplication sharedApplication] keyWindow] rootViewController] does not return `nil`.");
        return NO;
    }
    switch (type) {
        case HZAdTypeInterstitial: {
            return NO;
            break;
        }
        default: {
            return [[HZUnityAds sharedInstance] canShowAds];
            break;
        }
    }
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // AdColony auto-prefetches
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (type == HZAdTypeIncentivized) {
        self.isShowingIncentivized = YES;
        [[HZUnityAds sharedInstance] setZone:self.incentivizedZoneID];
    } else {
        self.isShowingIncentivized = NO;
        [[HZUnityAds sharedInstance] setZone:self.videoZoneID];
    }
    [[HZUnityAds sharedInstance] show];
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
    if (self.isShowingIncentivized) {
        if (skipped) {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        } else {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
        }
    }
    self.isShowingIncentivized = NO;
}

- (void)unityAdsDidHide {
    [self.delegate adapterDidDismissAd:self];
}

- (void)unityAdsWillLeaveApplication {
    [self.delegate adapterWasClicked:self];
}

- (void)unityAdsVideoStarted {
    [self.delegate adapterWillPlayAudio:self];
}

@end