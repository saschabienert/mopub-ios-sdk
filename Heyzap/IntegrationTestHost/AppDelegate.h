//
//  AppDelegate.h
//  IntegrationTestHost
//
//  Created by Maximilian Tagher on 10/9/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  The Integration Test Host is just a (mostly) empty app to use as a host for our integration tests.
 *  Since the regular test app interacts with the SDK in mutually incompatible ways (like using the delegate properties and auto fetching), we can't use that.
 */
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

