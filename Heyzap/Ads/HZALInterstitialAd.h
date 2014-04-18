//
//  HZALInterstitialAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
#import <UIKit/UIKit.h>

@class HZALAdService;
@class HZALAd;
@protocol HZALAdVideoPlaybackDelegate;

@protocol HZALAdLoadDelegate <NSObject>

- (void)adService:(HZALAdService *)adService didLoadAd:(HZALAd *)ad;

- (void)adService:(HZALAdService *)adService didFailToLoadAdWithError:(int)code;

@end

@protocol HZALAdDisplayDelegate <NSObject>

- (void)ad:(HZALAd *)ad wasDisplayedIn:(UIView *)view;

- (void)ad:(HZALAd *)ad wasHiddenIn:(UIView *)view;

- (void)ad:(HZALAd *)ad wasClickedIn:(UIView *)view;

@end

@class HZALSdk;

@interface HZALInterstitialAd : HZClassProxy

@property (strong, atomic) id<HZALAdLoadDelegate> adLoadDelegate;
@property (strong, atomic) id<HZALAdDisplayDelegate> adDisplayDelegate;
@property (strong, atomic) id<HZALAdVideoPlaybackDelegate> adVideoPlaybackDelegate;

- (id)initInterstitialAdWithSdk:(HZALSdk *)anSdk;

- (void)showOver:(UIWindow *)window;

@end
