//
//  AppDelegate.h
//  HeyzapSDKTest
//
//  Created by Daniel Rhodes on 5/30/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdDelegate.h"

@class SDKTestAppViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AdDelegate *adDelegate;
@property (strong, nonatomic) SDKTestAppViewController *controller;
@property (strong, nonatomic) UINavigationController *navController;

@end
