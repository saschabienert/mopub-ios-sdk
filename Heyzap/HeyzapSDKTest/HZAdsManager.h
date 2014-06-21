//
//  HZAdsManager.h
//  Heyzap
//
//  Created by Daniel Rhodes on 8/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HeyzapAds.h"

@class HZAdModel;
@class HZAdViewController;

@interface HZAdsManager : NSObject

#pragma mark - Identity
@property (nonatomic, strong) NSString *publisherID;

#pragma mark - Debugging
@property (nonatomic, assign) BOOL isDebuggable;

#pragma mark - Active Controller
@property (nonatomic, assign) HZAdViewController *activeController;
@property (nonatomic, assign, readonly) BOOL isEnabled;
@property (nonatomic, assign) HZAdOptions options;

#pragma mark - Framework/Mediators
@property (nonatomic) NSString *framework;
@property (nonatomic) NSString *mediator;

+ (HZAdsManager *)sharedManager;
- (void) onStart;
+ (BOOL) isEnabled;
- (BOOL) isOptionEnabled: (HZAdOptions) adOption;
- (void) showForAdUnit: (NSString *) adUnit andTag: (NSString *) tag withCompletion: (void (^)(BOOL result, NSError *error))completion;
- (void) hideActiveAd;

- (void) setVideoDelegate: (id<HZAdsDelegate>) delegate;
- (void) setInterstitialDelegate: (id<HZAdsDelegate>) delegate;
- (void) setIncentivizedDelegate:(id<HZIncentivizedAdDelegate>)incentivizedDelegate;
- (id)delegateForAdUnit:(NSString *)adUnit;

@end
