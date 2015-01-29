//
//  HZFBInterstitialAd.h
//  Heyzap
//
//  Created by David Stumm on 12/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "HZClassProxy.h"

@protocol HZFBInterstitialAdDelegate;

@interface HZFBInterstitialAd : HZClassProxy
@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, weak) id<HZFBInterstitialAdDelegate> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID;
- (BOOL)isAdValid;
- (void)loadAd;
- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController;
@end

@protocol HZFBInterstitialAdDelegate <NSObject>
@optional
- (void)interstitialAdDidClick:(HZFBInterstitialAd *)interstitialAd;
- (void)interstitialAdDidClose:(HZFBInterstitialAd *)interstitialAd;
- (void)interstitialAdWillClose:(HZFBInterstitialAd *)interstitialAd;
- (void)interstitialAdDidLoad:(HZFBInterstitialAd *)interstitialAd;
- (void)interstitialAd:(HZFBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error;
- (void)interstitialAdWillLogImpression:(HZFBInterstitialAd *)interstitialAd;
@end
