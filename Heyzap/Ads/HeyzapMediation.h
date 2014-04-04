//
//  HeyzapMediation.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

@interface HeyzapMediation : NSObject

+ (instancetype)sharedInstance;

#pragma mark - Setup

- (void)start;

#pragma mark - Showing Ads

- (void)showAdForAdUnitType:(HZAdType)adType tag:(NSString *)tag;

- (BOOL)isAvailableForAdUnitType:(HZAdType)adType tag:(NSString *)tag;

// Need Delegate API for getting the current view controller.
// We can handle the common scenarios by recursively finding the right view controller. 

@end
