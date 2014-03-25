//
//  HZGADInterstitialDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZGADInterstitial;
@class HZGADRequestError;

// Delegate for receiving state change messages from a GADInterstitial such as
// interstitial ad requests succeeding/failing.
@protocol HZGADInterstitialDelegate<NSObject>

@optional

#pragma mark Ad Request Lifecycle Notifications

// Sent when an interstitial ad request succeeded.  Show it at the next
// transition point in your application such as when transitioning between view
// controllers.
- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad;

// Sent when an interstitial ad request completed without an interstitial to
// show.  This is common since interstitials are shown sparingly to users.
- (void)interstitial:(HZGADInterstitial *)ad didFailToReceiveAdWithError:(HZGADRequestError *)error;

#pragma mark Display-Time Lifecycle Notifications

// Sent just before presenting an interstitial.  After this method finishes the
// interstitial will animate onto the screen.  Use this opportunity to stop
// animations and save the state of your application in case the user leaves
// while the interstitial is on screen (e.g. to visit the App Store from a link
// on the interstitial).
- (void)interstitialWillPresentScreen:(HZGADInterstitial *)ad;

// Sent before the interstitial is to be animated off the screen.
- (void)interstitialWillDismissScreen:(HZGADInterstitial *)ad;

// Sent just after dismissing an interstitial and it has animated off the
// screen.
- (void)interstitialDidDismissScreen:(HZGADInterstitial *)ad;

// Sent just before the application will background or terminate because the
// user clicked on an ad that will launch another application (such as the App
// Store).  The normal UIApplicationDelegate methods, like
// applicationDidEnterBackground:, will be called immediately before this.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad;

@end

