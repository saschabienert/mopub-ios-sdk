//
//  HZVGVunglePub.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HZClassProxy.h"

@class HZVGStatusData;

@protocol HZVGVunglePubDelegate <NSObject>
@optional

- (void)vungleStatusUpdate:(HZVGStatusData *)statusData;

@end

@interface HZVGVunglePub : HZClassProxy

+ (BOOL)adIsAvailable;

+ (void)playModalAd:(UIViewController *)controller animated:(BOOL)animated;

+ (void)startWithPubAppID:(NSString *)pubAppID;

+ (void)setDelegate:(id<HZVGVunglePubDelegate>)delegate;

+ (void)playIncentivizedAd:(UIViewController*)controller animated:(BOOL)animated showClose:(BOOL)flag userTag:(NSString *)user;

@end
