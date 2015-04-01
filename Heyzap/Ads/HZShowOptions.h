//
//  HZShowOptions.h
//  Heyzap
//
//  Created by Mike Urbach on 3/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HeyzapAds.h"

/** HZShowOptions allows you to pass options to configure how ads are shown */
@interface HZShowOptions : NSObject <NSCopying>

/**
 *  @discussion A UIViewController that should present the ad being shown. If not specified the application's key window's root view controller is used.
 */
@property (nonatomic, weak) UIViewController *viewController;

/**
 *  @discussion An identifier for the location of the ad, which you can use to disable the ad from your dashboard. If not specified the tag "default" is always used.
 */
@property (nonatomic, strong) NSString *tag;

/**
 *  @discussion A block called when the ad is shown or fails to show. `result` states whether the show was successful; the error object describes the issue, if there was one.
 */
@property (nonatomic, copy) void (^completion)(BOOL result, NSError *error);

@end
