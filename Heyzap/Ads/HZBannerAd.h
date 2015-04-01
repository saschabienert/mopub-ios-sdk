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

@protocol HZBannerAdDelegate <NSObject>

//@optional

/// @name Ad Request Notifications
#pragma mark - Ad Request Notifications

/**
 *  Called when the banner ad is loaded.
 */
- (void)bannerDidReceiveAd;

/**
 *  Called when the banner ad fails to load.
 *
 *  @param error An error describing the failure. 
 *
 *  If the underlying ad network provided an `NSError` object, it will be accessible in the `userInfo` dictionary
 *  with the `NSUnderlyingErrorKey`.
 */
- (void)bannerDidFailToReceiveAd:(NSError *)error;

/// @name Click-time Notifications
#pragma mark - Click-time Notifications

/**
 *  Called when the user clicks the banner ad.
 */
- (void)bannerWasClicked;
/**
 *  Called when the banner ad will present a modal view controller, after the user clicks the ad.
 */
- (void)bannerWillPresentModalView;
/**
 *  Called when a presented modal view controller is dismissed by the user.
 */
- (void)bannerDidDismissModalView;
/**
 *  Called when a user clicks a banner ad that causes them to leave the application.
 */
- (void)bannerWillLeaveApplication;

@end

/**
 *  A wrapper around a mediated banner ad. This wrapper provides a unified interface to 
 */
@interface HZBannerAd : NSObject

+ (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAd *wrapper))completion;


@property (nonatomic, strong, readonly) UIView *mediatedBanner;
@property (nonatomic, weak) id<HZBannerAdDelegate> delegate;

@property (nonatomic, readonly) BOOL isLoaded;

/**
 *  An identifier of the ad network.
 * 
 *  Current values: "facebook", "admob", "iad"
 */
@property (nonatomic, strong, readonly) NSString *mediatedNetwork;

/**
 *  The height of the underlying banner. This method is implemented as `mediatedBanner.frame.size.height`. 
 */
@property (nonatomic, readonly) CGFloat adHeight;

+ (void)placeBannerInView:(UIView *)view
                 position:(HZBannerPosition)position
                  options:(HZBannerAdOptions *)options
               completion:(void (^)(NSError *error, HZBannerAd *ad))completion;

/**
 *  You must call this method when you're completely finished with the banner. Internally, our SDK keeps a strong reference to the `HZBannerAdWrapper` and we remove this reference when you call this method.
 *  This also calls `removeFromSuperview` on `mediatedBanner`.
 */
- (void)finishUsingBanner;

@end
