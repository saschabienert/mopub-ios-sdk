//
//  AppLovinDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZALInterstitialAd.h"
#import "HZBaseAdapter.h"
#import "HZALAdVideoPlaybackDelegate.h"

@protocol HZAppLovinDelegateReceiver;

/**
 *  AppLovin uses the same delegate protocols for Incentivized and Interstitial. This means that if you want updates on a per-ad-format basis, you need separate objects for each format.
 */
@interface HZAppLovinDelegate : NSObject <HZALAdLoadDelegate, HZALAdDisplayDelegate, HZALAdVideoPlaybackDelegate>

/**
 *  This property is for subclasses only.
 */
@property (nonatomic, weak) id<HZAppLovinDelegateReceiver>delegate;

- (id)initWithAdType:(HZAdType)adType delegate:(id<HZAppLovinDelegateReceiver>)delegate;

/**
 *  These methods report whether a video was viewed or not to the delegate, which will then forward the message on to the delegate receiver
 */
- (void)rewardValidationResult:(BOOL)success forAd:(HZALAd *) ad;
- (void)userDeclinedToViewAppLovinIncentivizedAd:(HZALAd *)ad;

@end
