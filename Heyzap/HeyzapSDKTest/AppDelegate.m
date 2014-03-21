//
//  AppDelegate.m
//  HeyzapSDKTest
//
//  Created by Daniel Rhodes on 5/30/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "AppDelegate.h"
//#import <Heyzap/Heyzap.h>

#import "HeyzapAds.h"
#import "HZLog.h"

#import "HZInterstitialAd.h"
#import "SDKTestAppViewController.h"

#if INTEGRATION_TESTING
#import <Subliminal/Subliminal.h>
#endif

#import "HZDevice.h"
#import "SDCSegmentedViewController.h"
#import "ServerSelectionViewController.h"
#import "DeviceInfoViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    if (![HZDevice hzSystemVersionIsLessThan: @"7.0"]) {
        [[UINavigationBar appearance] setBarTintColor: [UIColor colorWithRed: 39/255.0 green: 115/255.0 blue: 179/255.0 alpha: 0.5]];
        [[UINavigationBar appearance] setTitleTextAttributes: @{
            UITextAttributeTextColor: [UIColor whiteColor],
            UITextAttributeFont: [UIFont boldSystemFontOfSize: 24.0]
        }];
        
    }
    [HZLog setDebugLevel: HZDebugLevelVerbose];
    
    
    self.controller = [[SDKTestAppViewController alloc] init];
    
    
    [HeyzapAds startWithOptions: HZAdOptionsDisableAutoPrefetching];
    [HeyzapAds setDelegate: self.controller];
    [HeyzapAds setIncentiveDelegate: self.controller];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
    ServerSelectionViewController *serverController = [[ServerSelectionViewController alloc] init];
    DeviceInfoViewController *deviceController = [[DeviceInfoViewController alloc] init];
    SDCSegmentedViewController *segmentedController = [[SDCSegmentedViewController alloc] initWithViewControllers:@[self.controller, serverController,deviceController]];

    if ([segmentedController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        segmentedController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    
    self.navController = [[UINavigationController alloc] initWithRootViewController: segmentedController];
    
    segmentedController.position = SDCSegmentedViewControllerControlPositionNavigationBar;
    segmentedController.segmentedControl.tintColor = [UIColor whiteColor];
    
    [self.window setRootViewController: self.navController];
    [self.window makeKeyAndVisible];
    
#if INTEGRATION_TESTING
//    [SLTestController sharedTestController].shouldWaitToStartTesting = YES;
    [[SLTestController sharedTestController] runTests:[SLTest allTests] withCompletionBlock:nil];
#endif
    
    return YES;
}



@end
