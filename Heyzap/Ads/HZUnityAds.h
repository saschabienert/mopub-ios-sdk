//
//  HZUnityAds.h
//  Heyzap
//
//  Created by David Stumm on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HZClassProxy.h"

@protocol HZUnityAdsDelegate <NSObject>

@required
- (void)unityAdsVideoCompleted:(NSString *)rewardItemKey skipped:(BOOL)skipped;

@optional
- (void)unityAdsWillShow;
- (void)unityAdsDidShow;
- (void)unityAdsWillHide;
- (void)unityAdsDidHide;
- (void)unityAdsWillLeaveApplication;
- (void)unityAdsVideoStarted;
- (void)unityAdsFetchCompleted;
- (void)unityAdsFetchFailed;
@end

@interface HZUnityAds : HZClassProxy

@property (nonatomic, weak) id<HZUnityAdsDelegate> delegate;

+ (HZUnityAds *)sharedInstance;
+ (BOOL)isSupported;
+ (NSString *)getSDKVersion;

- (void)setTestDeveloperId:(NSString *)developerId;
- (void)setTestOptionsId:(NSString *)optionsId;
- (void)setDebugMode:(BOOL)debugMode;
- (void)setTestMode:(BOOL)testModeEnabled;

// UnityAds is currently distributing a separate version of their SDK from the Unity Asset Store
// The Asset store version is based off their network-selection branch; see https://github.com/Applifier/unity-ads/tree/network-selection
// (We need to support both to have a good installation UX)

// **
// REGULAR SDK ONLY functions
- (BOOL)canShowAds;
// ** ASSET STORE SDK ONLY functions
- (BOOL)canShowAds:(NSString *)network;
- (void)setNetworks:(NSString *)networks; // Comma separated list of networks
- (void)setNetwork:(NSString *)network;
// **

- (BOOL)isDebugMode;
- (BOOL)startWithGameId:(NSString *)gameId andViewController:(UIViewController *)viewController;
- (BOOL)startWithGameId:(NSString *)gameId;
- (BOOL)setViewController:(UIViewController *)viewController;

- (BOOL)canShow;
- (BOOL)setZone:(NSString *)zoneId;
- (BOOL)setZone:(NSString *)zoneId withRewardItem:(NSString *)rewardItemKey;
- (BOOL)show:(NSDictionary *)options;
- (BOOL)show;
- (BOOL)hide;
- (void)stopAll;
- (BOOL)hasMultipleRewardItems;
- (NSArray *)getRewardItemKeys;
- (NSString *)getDefaultRewardItemKey;
- (NSString *)getCurrentRewardItemKey;
- (BOOL)setRewardItemKey:(NSString *)rewardItemKey;
- (void)setDefaultRewardItemAsRewardItem;
- (NSDictionary *)getRewardItemDetailsWithKey:(NSString *)rewardItemKey;
@end
