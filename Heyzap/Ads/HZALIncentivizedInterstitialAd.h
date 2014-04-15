//
//  HZALIncentivizedInterstitialAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
#import <UIKit/UIKit.h>

@class HZALSdk;
@protocol HZALAdLoadDelegate;
@protocol HZALAdRewardDelegate;
@protocol HZALAdDisplayDelegate;

@interface HZALIncentivizedInterstitialAd : HZClassProxy

@property (strong, nonatomic) id<HZALAdDisplayDelegate> adDisplayDelegate;

- (instancetype)initIncentivizedInterstitialWithSdk:(HZALSdk *)anSdk;

- (void)preloadAndNotify:(id<HZALAdLoadDelegate>)adLoadDelegate;

- (void)showOver:(UIWindow *)window andNotify:(id<HZALAdRewardDelegate>)adRewardDelegate;

@end
