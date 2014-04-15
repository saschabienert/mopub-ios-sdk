//
//  ALAdLoadDelegate.h
//  sdk
//
//  Created by Basil on 3/23/12.
//  Copyright (c) 2013, AppLovin Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAd.h"

// Indicates that no ads are currently eligible for your device & location.
#define kALErrorCodeNoFill 204

// Indicates that a network request timed out.
#define kALErrorCodeAdRequestNetworkTimeout -1001

// Indicates that an unspecified network issue occured, for instance if the user is in Airplane Mode.
#define kALErrorCodeAdRequestUnspecifiedError -1

/**
 * This protocol defines a listener for ad load events.
 *
 * @author Basil Shikin, Matt Szaro
 * @since 2.0
 */
@class ALAdService;

@protocol ALAdLoadDelegate <NSObject>

/**
 * This method is invoked when an ad is loaded by the AdService.
 *
 * This method is invoked on the main UI thread.
 *
 * @param adService AdService which loaded the ad. Guranteed not to be null.
 * @param ad        Ad that was loaded. Guranteed not to be null.
 */
-(void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad;

/**
 * This method is invoked when an ad load fails.
 *
 * This method is invoked on the main UI thread.
 *
 * @param adService AdService which failed to load an ad. Guranteed not to be null.
 * @param code      Error code describing the cause of failure. 
 */
-(void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code;

@end
