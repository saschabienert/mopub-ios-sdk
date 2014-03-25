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

@property(nonatomic, copy) NSString *adUnitID;
@property(nonatomic, readonly, assign) BOOL isReady;

- (id)init;

- (void)loadRequest:(HZGADRequest *)request;

- (void)presentFromRootViewController:(UIViewController *)rootViewController;

@end
