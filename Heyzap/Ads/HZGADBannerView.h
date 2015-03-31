//
//  HZGADBannerView.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
@import UIKit;


@class HZGADBannerView;
@class HZGADRequest;
@class HZGADRequestError;

@protocol HZGADBannerViewDelegate<NSObject>

@optional

- (void)adViewDidReceiveAd:(HZGADBannerView *)view;
- (void)adView:(HZGADBannerView *)view didFailToReceiveAdWithError:(HZGADRequestError *)error;
- (void)adViewWillPresentScreen:(HZGADBannerView *)adView;
- (void)adViewWillDismissScreen:(HZGADBannerView *)adView;
- (void)adViewDidDismissScreen:(HZGADBannerView *)adView;
- (void)adViewWillLeaveApplication:(HZGADBannerView *)adView;

typedef struct HZGADAdSize {
    CGSize size;
    NSUInteger flags;
} HZGADAdSize;

@end


/**
 *  NB: The superview of the proxied class is a `UIView`. If you need to call `UIView` methods on in, simply cast it to a (UIView *) first.
 */
@interface HZGADBannerView : HZClassProxy

/// Initializes a GADBannerView and sets it to the specified size, and specifies its placement
/// within its superview bounds. Returns nil if |adSize| is an invalid ad size.
- (instancetype)initWithAdSize:(HZGADAdSize)adSize origin:(CGPoint)origin;

/// Initializes a GADBannerView and sets it to the specified size, and specifies its placement at
/// the top left of its superview. Returns nil if |adSize| is an invalid ad size.
- (instancetype)initWithAdSize:(HZGADAdSize)adSize;

#pragma mark Pre-Request

/// Required value created on the AdMob website. Create a new ad unit for every unique placement of
/// an ad in your application. Set this to the ID assigned for this placement. Ad units are
/// important for targeting and statistics.
///
/// Example AdMob ad unit ID: @"ca-app-pub-0123456789012345/0123456789"
@property(nonatomic, copy) IBInspectable NSString *adUnitID;

/// Required reference to the current root view controller. For example the root view controller in
/// tab-based application would be the UITabViewController. Remember to nil or update this property
/// before deallocating the view controller.
@property(nonatomic, weak) IBOutlet UIViewController *rootViewController;

/// Required to set this banner view to a proper size. Never create your own GADAdSize directly. Use
/// one of the predefined standard ad sizes (such as kGADAdSizeBanner), or create one using the
/// GADAdSizeFromCGSize method. If not using mediation, then changing the adSize after an ad has
/// been shown will cause a new request (for an ad of the new size) to be sent. If using mediation,
/// then a new request may not be sent.
@property(nonatomic, assign) HZGADAdSize adSize;

/// Optional delegate object that receives state change notifications from this GADBannerView.
/// Typically this is a UIViewController. Remember to nil this property before deallocating the
/// delegate.
@property(nonatomic, weak) IBOutlet id<HZGADBannerViewDelegate> delegate;

/// Optional delegate object that receives in-app purchase notifications from this ad. Required for
/// the custom in-app purchase flow, but ignored when using the default in-app purchase flow.
/// Remember to nil this property before deallocating the delegate.
//@property(nonatomic, weak) IBOutlet id<GADInAppPurchaseDelegate> inAppPurchaseDelegate;

#pragma mark Making an Ad Request

/// Makes an ad request. The request object supplies targeting information.
- (void)loadRequest:(HZGADRequest *)request;

///// A Boolean value that determines whether autoloading of ads in the receiver is enabled. If
///// enabled, you do not need to call the loadRequest: method to load ads.
//@property(nonatomic, assign, getter=isAutoloadEnabled) IBInspectable BOOL autoloadEnabled;

//#pragma mark Deprecated

/// Indicates if the currently displayed ad (or most recent failure) was a result of auto refreshing
/// as specified on server. This property is set to NO after each loadRequest: method.
//@property(nonatomic, readonly, assign) BOOL hasAutoRefreshed __attribute__((deprecated));

/// The mediated ad network's underlying ad view. You may use this property to read the ad's actual
/// size and adjust this banner view's frame origin. However, modifying the banner view's frame size
/// triggers the Mobile Ads SDK to request a new ad. Only update the banner view's frame origin.
//@property(nonatomic, readonly, weak) UIView *mediatedAdView
//__attribute__((deprecated("Use adNetworkClassName.")));

@end
