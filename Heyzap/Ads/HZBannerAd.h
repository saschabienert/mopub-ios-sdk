//
//  HZBannerAdWrapper.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
@class HZBannerAdOptions;

typedef NS_ENUM(NSUInteger, HZBannerPosition) {
    HZBannerPositionTop,
    HZBannerPositionBottom,
};

// In addition to the delegate methods, Heyzap also posts `NSNotification`s for each event. Each the notification's `object` property will the `HZBannerAd` instance issuing the notification.

// This approach gives you the flexibility to have multiple objects listening for information about banners.
// Since notifications aren't coupled to individual `HZBannerAd` instances, they also ease integration with components not directly related to displaying banners (e.g. an analytics object tracking clicks).
// Additionally, since listeners are only weakly coupled to individual `HZBannerAd` instances, this also eases integration with

extern NSString * const kHZBannerAdDidReceiveAdNotification;
extern NSString * const kHZBannerAdDidFailToReceiveAdNotification;
extern NSString * const kHZBannerAdWasClickedNotification;
extern NSString * const kHZBannerAdWillPresentModalViewNotification;
extern NSString * const kHZBannerAdDidDismissModalViewNotification;
extern NSString * const kHZBannerAdWillLeaveApplicationNotification;

// The `userInfo` property uses the keys listed below.

/**
 *  The error causing the banner to not load an ad. This key is only available for the `kHZBannerAdDidFailToReceiveAdNotification` notification.
 */
extern NSString * const kHZBannerAdNotificationErrorKey;

@class HZBannerAd;

@protocol HZBannerAdDelegate <NSObject>

@optional

/// @name Ad Request Notifications
#pragma mark - Ad Request Notifications

/**
 *  Called when the banner ad is loaded.
 */
- (void)bannerDidReceiveAd:(HZBannerAd *)banner;

/**
 *  Called when the banner ad fails to load.
 *
 *  @param error An error describing the failure. 
 *
 *  If the underlying ad network provided an `NSError` object, it will be accessible in the `userInfo` dictionary
 *  with the `NSUnderlyingErrorKey`.
 */
- (void)bannerDidFailToReceiveAd:(HZBannerAd *)banner error:(NSError *)error;

/// @name Click-time Notifications
#pragma mark - Click-time Notifications

/**
 *  Called when the user clicks the banner ad.
 */
- (void)bannerWasClicked:(HZBannerAd *)banner;
/**
 *  Called when the banner ad will present a modal view controller, after the user clicks the ad.
 */
- (void)bannerWillPresentModalView:(HZBannerAd *)banner;
/**
 *  Called when a presented modal view controller is dismissed by the user.
 */
- (void)bannerDidDismissModalView:(HZBannerAd *)banner;
/**
 *  Called when a user clicks a banner ad that causes them to leave the application.
 */
- (void)bannerWillLeaveApplication:(HZBannerAd *)banner;

@end

/**
 *  A wrapper around a mediated banner ad. This wrapper provides a unified interface to 
 */
@interface HZBannerAd : UIView

+ (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAd *wrapper))completion;

@property (nonatomic, weak) id<HZBannerAdDelegate> delegate;

@property (nonatomic, readonly) BOOL isLoaded;

/**
 *  The options used to create the banner ad. You can use this property to access things like the `tag` or `presentingViewController` for the banner.
 */
@property (nonatomic, readonly, copy) HZBannerAdOptions *options;

/**
 *  An identifier of the ad network.
 * 
 *  Current values: "facebook", "admob", "iad"
 */
@property (nonatomic, strong, readonly) NSString *mediatedNetwork;

/**
 *  Fetches a banner and places it in the view.
 *
 *  @param view       The view to place the banner in. If `view == options.presentingViewController.view`, the view controller's top/bottom layout guides are taken into consideration when placing the view.
 *  @param position   The position, either top or bottom, to place the view in.
 *  @param options    Configuration options to use for the banner.
 *  @param completion A block called when the banner fetch either succeeds or fails.
 */
+ (void)placeBannerInView:(UIView *)view
                 position:(HZBannerPosition)position
                  options:(HZBannerAdOptions *)options
               completion:(void (^)(NSError *error, HZBannerAd *wrapper))completion;

@end
