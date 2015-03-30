//
//  HZBannerAdWrapper_Private.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdWrapper.h"

@class HZBannerAdapter;

@protocol HZBannerAdWrapperReporter <NSObject>

/**
 *  Called when the banner ad is loaded.
 */
- (void)didReceiveAd;

/**
 *  Called when the banner ad fails to load.
 *
 *  @param error An error describing the failure.
 *
 *  If the underlying ad network provided an `NSError` object, it will be accessible in the `userInfo` dictionary
 *  with the `NSUnderlyingErrorKey`.
 */
- (void)didFailToReceiveAd:(NSError *)error;

/// @name Click-time Notifications
#pragma mark - Click-time Notifications

/**
 *  Called when the user clicks the banner ad.
 */
- (void)userDidClick;
/**
 *  Called when the banner ad will present a modal view controller, after the user clicks the ad.
 */
- (void)willPresentModalView;
/**
 *  Called when a presented modal view controller is dismissed by the user.
 */
- (void)didDismissModalView;
/**
 *  Called when a user clicks a banner ad that causes them to leave the application.
 */
- (void)willLeaveApplication;

@end

@interface HZBannerAdWrapper() <HZBannerAdWrapperReporter>


- (instancetype)initWithBanner:(HZBannerAdapter *)adapter;

@end
