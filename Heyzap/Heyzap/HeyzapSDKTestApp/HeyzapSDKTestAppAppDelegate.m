//
//  HeyzapSDKTestAppAppDelegate.m
//  HeyzapSDKTestApp
//
//  Created by Daniel Rhodes on 8/15/11.
//  Copyright 2011 Heyzap. All rights reserved.
//

#import "HeyzapSDKTestAppAppDelegate.h"
#import "HeyzapSDKTestAppViewController.h"
#import <GameKit/GameKit.h>
#ifndef ADS_ONLY_SDK
    #import "HeyzapSDKPrivate.h"
    #import "HeyzapSDKTestAppAppDelegate+URLStuff.h"
#else
    #import <HeyzapAds/HeyzapAds.h>
#endif

@implementation HeyzapSDKTestAppAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
        if (localPlayer.isAuthenticated) {
            // Perform additional tasks for the authenticated player.
        } else {
        }
    }];
#ifndef ADS_ONLY_SDK
    [HeyzapSDK setAppName:@"My app!"];
    [HeyzapSDK startHeyzapWithAppId:@"999999" andAppURL:[NSURL URLWithString: @"hztestapp://"] andOptions:HZOptionsNone];
    //[HeyzapSDK startHeyzapWithAppId: @"999999" andAppURL: [NSURL URLWithString: @"hztestapp://"] andShowPopop:NO];
    //335536974 is actual app id we're using
    [[HeyzapSDK sharedSDK] setDebugLevel: HZDebugLevelError];
    
    [[HeyzapSDK sharedSDK] onStartLevel:^(NSString *levelID) {
        NSLog(@"YAY CALLL BACK: %@", levelID);
    }];
#else
    [HeyzapAds startWithAppStoreID: 999999 andOptions:HZAdOptionsNone];
#endif
    
    // Override point for customization after application launch.
    
    self.window.rootViewController = [[HeyzapSDKTestAppViewController alloc] init];
#ifndef ADS_ONLY_SDK
    [[HeyzapSDK sharedSDK] enableAds:self.window.rootViewController];
#else
    [HZInterstitialAd setDelegate: self.window.rootViewController];
#endif
    [self.window makeKeyAndVisible];
    
    
    return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application
{
 

    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
//{
//    
//    if ([HeyzapSDK canParseURL:url]) {
//        NSDictionary *components = [HeyzapSDK parseURL:url];
//        NSString *requestType = [components objectForKey:kHeyzapRequestTypeKey];
//        NSDictionary *requestArguments = [components objectForKey:kHeyzapRequestArgumentsKey];
//        if ([requestType isEqualToString:@"level"]) {
//            NSString *levelIdentifier = [requestArguments objectForKey:@"level"];
//            /* Go to the level */
//        }
//        
//        return YES;
//    }
//    
//    // (Handle other URLs you might be receiving)
//    return NO;
//}


@end
