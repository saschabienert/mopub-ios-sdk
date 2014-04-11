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

#import "HZInterstitialAd.h"

#if MEDIATION
#import "MediationTestAppViewController.h"
#endif

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
    
    [HZLog setDebugLevel: HZDebugLevelError];
    
//#if MEDIATION
//    UIViewController *mainController = [[MediationTestAppViewController alloc] init];
//#else
    UIViewController *mainController = [[SDKTestAppViewController alloc] init];
//#endif
    
    
    [HeyzapAds startWithOptions: HZAdOptionsDisableAutoPrefetching];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
    ServerSelectionViewController *serverController = [[ServerSelectionViewController alloc] init];
    DeviceInfoViewController *deviceController = [[DeviceInfoViewController alloc] init];
    SDCSegmentedViewController *segmentedController = [[SDCSegmentedViewController alloc] initWithViewControllers:@[mainController, serverController,deviceController]];

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
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
//        [HZInterstitialAd show];
//    });
    
    return YES;
}



@end
