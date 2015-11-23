//
//  HZFBNativeAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZFBAdImage;
@protocol HZFBNativeAdDelegate;

typedef NS_ENUM(NSInteger, HZFBNativeAdsCachePolicy) {
    HZFBNativeAdsCachePolicyNone = 0,
    HZFBNativeAdsCachePolicyIcon = 0x1,
    HZFBNativeAdsCachePolicyCoverImage = 0x2,
    HZFBNativeAdsCachePolicyAll = HZFBNativeAdsCachePolicyCoverImage | HZFBNativeAdsCachePolicyIcon,
};

@interface HZFBNativeAd : HZClassProxy

@property (nonatomic, copy, readonly, nonnull) NSString *placementID;

/*!
 @property
 @abstract Typed access to the ad title.
 */
@property (nonatomic, copy, readonly, nullable) NSString *title;
/*!
 @property
 @abstract Typed access to the ad subtitle.
 */
@property (nonatomic, copy, readonly, nullable) NSString *subtitle;

/*!
 @property
 @abstract Typed access to the call to action phrase of the ad, for example "Install Now".
 */
@property (nonatomic, copy, readonly, nullable) NSString *callToAction;
/*!
 @property
 @abstract Typed access to the ad icon. See `FBAdImage` for details.
 */
@property (nonatomic, strong, readonly, nullable) HZFBAdImage *icon;
/*!
 @property
 @abstract Typed access to the ad cover image creative. See `FBAdImage` for details.
 */
@property (nonatomic, strong, readonly, nullable) HZFBAdImage *coverImage;
/*!
 @property
 @abstract Typed access to the body text, usually a longer description of the ad.
 */
@property (nonatomic, copy, readonly, nullable) NSString *body;
/*!
 @property
 
 @abstract Set the native ad caching policy. This controls which media from the native ad are cached before the native ad calls nativeAdLoaded on its delegate. The default is to not block on caching.
 */
@property (nonatomic, assign) HZFBNativeAdsCachePolicy mediaCachePolicy;
/*!
 @property
 @abstract the delegate
 */
@property (nonatomic, weak, nullable) id<HZFBNativeAdDelegate> delegate;

/*!
 @method
 
 @abstract
 This is a method to initialize a FBNativeAd object matching the given placement id.
 
 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 */
- (nonnull instancetype)initWithPlacementID:(nonnull NSString *)placementID NS_DESIGNATED_INITIALIZER;

/*!
 @method
 
 @abstract
 This is a method to associate a FBNativeAd with the UIView you will use to display the native ads.
 
 @param view The UIView you created to render all the native ads data elements.
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information) or the in-app browser.
 
 @discussion The whole area of the UIView will be clickable.
 */
- (void)registerViewForInteraction:(nonnull UIView *)view
                withViewController:(nonnull UIViewController *)viewController;

/*!
 @method
 
 @abstract
 This is a method to associate FBNativeAd with the UIView you will use to display the native ads
 and set clickable areas.
 
 @param view The UIView you created to render all the native ads data elements.
 @param viewController The UIViewController that will be used to present SKStoreProductViewController
 (iTunes Store product information).
 @param clickableViews An array of UIView you created to render the native ads data element, e.g.
 CallToAction button, Icon image, which you want to specify as clickable.
 */
- (void)registerViewForInteraction:(nonnull UIView *)view
                withViewController:(nonnull UIViewController *)viewController
                withClickableViews:(nonnull NSArray *)clickableViews;

/*!
 @method
 
 @abstract
 This is a method to disconnect a FBNativeAd with the UIView you used to display the native ads.
 */
- (void)unregisterView;

/*!
 @method
 
 @abstract
 Begins loading the FBNativeAd content.
 
 @discussion You can implement `nativeAdDidLoad:` and `nativeAd:didFailWithError:` methods
 of `FBNativeAdDelegate` if you would like to be notified as loading succeeds or fails.
 */
- (void)loadAd;

/*!
 @property
 
 @abstract
 Call isAdValid to check whether native ad is valid & internal consistent prior rendering using its properties. If
 rendering is done as part of the loadAd callback, it is guarantee to be consistent
 */
@property (nonatomic, getter=isAdValid, readonly) BOOL adValid;

@end
