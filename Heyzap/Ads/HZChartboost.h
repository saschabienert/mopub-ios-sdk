//
//  HZChartboostClassProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/24/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZClassProxy.h"

@interface HZChartboost : HZClassProxy

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *appSignature;
@property (nonatomic, weak) id delegate;

+ (instancetype)sharedChartboost;

- (void)startSession;

- (void)cacheInterstitial;

- (BOOL)hasCachedInterstitial;

- (void)showInterstitial;


@end
