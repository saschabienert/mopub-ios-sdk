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

#import "HZUINavigationController.h"

#import "HZInterstitialAd.h"
#import "SDKTestAppViewController.h"

#import "HZDevice.h"
#import "HZSDCSegmentedViewController.h"
#import "ServerSelectionViewController.h"
#import "DeviceInfoViewController.h"
#import "DemandTestViewController.h"

#import "HZInterstitialAd.h"
#import "PersistentTestAppConfiguration.h"
#import "HZHardcodedConstantChecker.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [HZHardcodedConstantChecker checkConstants];
    
    if (![HZDevice hzSystemVersionIsLessThan: @"7.0"]) {
        [[UINavigationBar appearance] setBarTintColor: [UIColor colorWithRed: 39/255.0 green: 115/255.0 blue: 179/255.0 alpha: 0.5]];
        [[UINavigationBar appearance] setTitleTextAttributes: @{
            UITextAttributeTextColor: [UIColor whiteColor],
            UITextAttributeFont: [UIFont boldSystemFontOfSize: 24.0]
        }];
    }
    
    [HZLog setDebugLevel: HZDebugLevelVerbose];
//    [HZLog setThirdPartyLoggingEnabled:YES];
    
    SDKTestAppViewController *mainController = [[SDKTestAppViewController alloc] init];
    
    const HZAdOptions opts = [PersistentTestAppConfiguration sharedConfiguration].autoPrefetch ? HZAdOptionsNone : HZAdOptionsDisableAutoPrefetching;
    [HeyzapAds startWithPublisherID: @"1234" andOptions:opts];
//    [HeyzapAds pauseExpensiveWork];
    
    [HeyzapAds setDelegate:mainController forNetwork:HZNetworkChartboost];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
    ServerSelectionViewController *serverController = [[ServerSelectionViewController alloc] init];
    DeviceInfoViewController *deviceController = [[DeviceInfoViewController alloc] init];
    DemandTestViewController *mraidController = [[DemandTestViewController alloc] init];
    
    HZSDCSegmentedViewController *segmentedController = [[HZSDCSegmentedViewController alloc] initWithViewControllers:@[mainController, serverController, mraidController, deviceController]];

    if ([segmentedController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        segmentedController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    
    self.navController = [[HZUINavigationController alloc] initWithRootViewController: segmentedController orientations:UIInterfaceOrientationMaskAll];
    
    segmentedController.position = HZSDCSegmentedViewControllerControlPositionNavigationBar;
    segmentedController.segmentedControl.tintColor = [UIColor whiteColor];
    
    [self.window setRootViewController: self.navController];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
