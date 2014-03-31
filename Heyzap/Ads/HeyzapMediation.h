//
//  HeyzapMediation.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HeyzapMediation : NSObject

+ (instancetype)sharedInstance;

#pragma mark - Setup

- (void)start;

#pragma mark - Showing Ads

- (void)showAd;

// Need Delegate API for getting the current view controller.
// We can handle the common scenarios by recursively finding the right view controller. 

@end
