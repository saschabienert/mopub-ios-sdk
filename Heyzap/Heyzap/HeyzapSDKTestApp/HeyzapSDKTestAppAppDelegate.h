//
//  HeyzapSDKTestAppAppDelegate.h
//  HeyzapSDKTestApp
//
//  Created by Daniel Rhodes on 8/15/11.
//  Copyright 2011 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifndef ADS_ONLY_SDK
    #import <Heyzap/Heyzap.h>
#endif


@class HeyzapSDKTestAppViewController;

@interface HeyzapSDKTestAppAppDelegate : NSObject <UIApplicationDelegate> {
}

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, strong) IBOutlet HeyzapSDKTestAppViewController *viewController;

@end
