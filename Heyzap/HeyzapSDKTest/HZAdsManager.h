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
#import "HZShowOptions.h"
#import "HZCreativeType.h"

@class HZAdModel;
@class HZAdViewController;

@interface HZAdsManager : NSObject

#pragma mark - Identity
@property (nonatomic, strong) NSString *publisherID;

#pragma mark - Debugging
@property (nonatomic) BOOL isDebuggable;

#pragma mark - Active Controller
@property (nonatomic, weak) HZAdViewController *activeController;

#pragma mark - Global Status Delegates
//@property (nonatomic, weak) id<HZAdsDelegate> statusDelegate;
//@property (nonatomic, weak) id<HZIncentivizedAdDelegate> incentivizedDelegate;

@property (nonatomic) HZAdOptions options;

#pragma mark - Framework/Mediators
@property (nonatomic) NSString *framework;
@property (nonatomic) NSString *mediator;

+ (HZAdsManager *)sharedManager;
- (void) onStart;
+ (BOOL) isEnabled;
+ (BOOL) isVersionSupported;
- (BOOL) isAdobeAir;
- (BOOL) isUnity3D;
- (BOOL) isOptionEnabled: (HZAdOptions) adOption;

- (BOOL)isAvailableForFetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType;
- (void)showForCreativeType:(HZCreativeType)creativeTypeToShow auctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options;
- (void) hideActiveAd;

+ (void)postNotificationName:(NSString *const)notificationName infoProvider:(id<HZAdInfoProvider>)infoProvider;
+ (void)postNotificationName:(NSString *const)notificationName infoProvider:(id<HZAdInfoProvider>)infoProvider userInfo:(NSDictionary *)userInfo;

#define HZVersionCheck()     if(![HZAdsManager isVersionSupported]){                \
                               HZELog(@"Heyzap only supports iOS 6.0 and above"); \
                               return;                                              \
                             }

#define HZVersionCheckBool() if(![HZAdsManager isVersionSupported]){                \
                               HZELog(@"Heyzap only supports iOS 6.0 and above"); \
                               return NO;                                           \
                             }

#define HZVersionCheckNil() if(![HZAdsManager isVersionSupported]){                \
                                HZELog(@"Heyzap only supports iOS 6.0 and above"); \
                                return nil;                                           \
                                }
@end
