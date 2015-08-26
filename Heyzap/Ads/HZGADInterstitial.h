//
//  HZGADInterstitial.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
#import <UIKit/UIKit.h>
#import "HZGADInterstitialDelegate.h"
@class HZGADRequest;

@interface HZGADInterstitial : HZClassProxy

@property(nonatomic, readonly, copy) NSString *adUnitID;
@property(nonatomic, readonly, assign) BOOL isReady;
@property(nonatomic, readonly, assign) BOOL hasBeenUsed;

@property(nonatomic, weak) NSObject<HZGADInterstitialDelegate> *delegate;

- (instancetype)initWithAdUnitID:(NSString *)adUnitID NS_DESIGNATED_INITIALIZER;

- (void)loadRequest:(HZGADRequest *)request;

- (void)presentFromRootViewController:(UIViewController *)rootViewController;

#pragma mark Deprecated

/// Deprecated intializer. Use initWithAdUnitID: instead.
- (instancetype)init;

/// Deprecated setter, use initWithAdUnitID: instead.
- (void)setAdUnitID:(NSString *)adUnitID;

@end
