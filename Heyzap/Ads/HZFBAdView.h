//
//  HZFBAdView.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
@import UIKit;

@class HZFBAdView;

@protocol HZFBAdViewDelegate <NSObject>

@optional

- (void)adViewDidClick:(HZFBAdView *)adView;
- (void)adViewDidFinishHandlingClick:(HZFBAdView *)adView;
- (void)adViewDidLoad:(HZFBAdView *)adView;
- (void)adView:(HZFBAdView *)adView didFailWithError:(NSError *)error;
- (void)adViewWillLogImpression:(HZFBAdView *)adView;
- (UIViewController *)viewControllerForPresentingModalView;

@end

/**
 *  NB: The superview of the proxied class is a `UIView`. If you need to call `UIView` methods on in, simply cast it to a (UIView *) first.
 */
@interface HZFBAdView : HZClassProxy

typedef struct HZFBAdSize {
    CGSize size;
} HZFBAdSize;

@property (nonatomic, weak) id<HZFBAdViewDelegate> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID
                             adSize:(HZFBAdSize)adSize
                 rootViewController:(UIViewController *)viewController;

- (void)loadAd;

@end
