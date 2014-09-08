//
//  HZApplifier.h
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

@interface HZApplifier : HZClassProxy

@property (nonatomic, weak) id<HZUnityAdsDelegate> delegate;

+ (HZApplifier *)sharedInstance;
+ (BOOL)isSupported;
+ (NSString *)getSDKVersion;

- (void)setTestDeveloperId:(NSString *)developerId;
- (void)setTestOptionsId:(NSString *)optionsId;
- (void)setDebugMode:(BOOL)debugMode;
- (void)setTestMode:(BOOL)testModeEnabled;

- (BOOL)isDebugMode;
- (BOOL)startWithGameId:(NSString *)gameId andViewController:(UIViewController *)viewController;
- (BOOL)startWithGameId:(NSString *)gameId;
- (BOOL)setViewController:(UIViewController *)viewController;
- (BOOL)canShowAds;
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
