//
//  HeyzapMediation.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HZMediator) {
    HZMediatorHeyzap,
    HZMediatorChartboost,
    HZMediatorAdColony,
    HZMediatorVungle,
    HZMediatorAdMob,
};

@interface HeyzapMediation : NSObject

+ (instancetype)sharedInstance;

#pragma mark - Setup

- (void)setupHeyzap;

- (void)setupChartboostWithAppID:(NSString *)appID appSignature:(NSString *)appSignature;

- (void)setupAdColonyWithAppID:(NSString *)appID zoneID:(NSString *)zoneID;

- (void)setupVungleWithAppID:(NSString *)appID;

- (void)setupAdMob;

- (void)finishedSettingUpMediators;

#pragma mark - Showing Ads

- (void)showAd;

@end
