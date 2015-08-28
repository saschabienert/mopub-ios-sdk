//
//  SDKTestAppViewControllerAdCallbackDelegate.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/27/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDKTestAppViewController.h"

@interface SDKTestAppViewControllerAdCallbackDelegate : NSObject
@property (nonatomic) SDKTestAppViewController *vc;
@property (nonatomic) NSString *name;

- (instancetype) initWthSDKTestAppViewController:(SDKTestAppViewController *)vc;

@end

@interface SDKTestAppViewControllerHZAdsDelegate : SDKTestAppViewControllerAdCallbackDelegate <HZAdsDelegate>

@end

@interface SDKTestAppViewControllerHZIncentivizedAdDelegate : SDKTestAppViewControllerHZAdsDelegate <HZIncentivizedAdDelegate>
@end

@interface SDKTestAppViewControllerHZBannerAdDelegate : SDKTestAppViewControllerAdCallbackDelegate <HZBannerAdDelegate>

@end