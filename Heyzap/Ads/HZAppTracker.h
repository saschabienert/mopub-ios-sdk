//
//  HZAppTracker.h
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
#import <UIKit/UIKit.h>

/**
 *  The proxy for AppTracker (from Leadbolt's SDK).
 */
@interface HZAppTracker : HZClassProxy

+(void) startSession:(NSString *)apiKey;
+(void) loadModuleToCache:(NSString*) placement;
+(void) loadModule:(NSString*) placement viewController:(UIViewController*)viewController;

+(void) setFramework:(NSString *)f;

@end
