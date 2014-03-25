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

@interface HZVGVunglePub : HZClassProxy

+ (BOOL)adIsAvailable;

+ (void)playModalAd:(UIViewController *)controller animated:(BOOL)animated;

+ (void)startWithPubAppID:(NSString*)pubAppID;

@end
