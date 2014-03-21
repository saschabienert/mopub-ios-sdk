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

#pragma mark - Debugging
@property (nonatomic, assign) BOOL isDebuggable;
@property (nonatomic, assign) int campaignIDPin;

#pragma mark - Active Controller
@property (nonatomic, assign) HZAdViewController *activeController;

#pragma mark - Global Status Delegates
@property (nonatomic, weak) id<HZAdsDelegate> statusDelegate;
@property (nonatomic, weak) id<HZIncentivizedAdDelegate> incentivizedDelegate;

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
@end
