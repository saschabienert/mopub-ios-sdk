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
@property (nonatomic, weak) HZAdViewController *activeController;

#pragma mark - Global Status Delegates
//@property (nonatomic, weak) id<HZAdsDelegate> statusDelegate;
//@property (nonatomic, weak) id<HZIncentivizedAdDelegate> incentivizedDelegate;

@property (nonatomic, assign) HZAdOptions options;
@property (nonatomic) BOOL isStarted;

#pragma mark - Framework/Mediators
@property (nonatomic) NSString *framework;
@property (nonatomic) NSString *mediator;

+ (HZAdsManager *)sharedManager;
- (void) onStart;
+ (BOOL) isEnabled;
- (BOOL) isOptionEnabled: (HZAdOptions) adOption;

- (BOOL)isAvailableForAdUnit:(NSString *)adUnit tag:(NSString *)tag auctionType:(HZAuctionType)auctionType;
- (void) showForAdUnit: (NSString *) adUnit andTag: (NSString *) tag auctionType:(HZAuctionType)auctionType withCompletion: (void (^)(BOOL result, NSError *error))completion;
- (void) hideActiveAd;

- (void)setInterstitialDelegate:(id<HZAdsDelegate>)delegate;
- (void)setIncentivizedDelegate:(id<HZIncentivizedAdDelegate>)delegate;
- (void)setVideoDelegate:(id<HZAdsDelegate>)delegate;

- (id)delegateForAdUnit:(NSString *)adUnit;

+ (void)postNotificationName:(NSString *const)notificationName infoProvider:(id<HZAdInfoProvider>)infoProvider;

#define HZVersionCheck if(![HZAdsManager isEnabled]){                           \
                           HZDLog(@"Heyzap only supports iOS 6.0.0 and above"); \
                           return;                                              \
                       }
#define HZVersionCheckBool if(![HZAdsManager isEnabled]){                           \
                               HZDLog(@"Heyzap only supports iOS 6.0.0 and above"); \
                               return NO;                                           \
                           }
@end
