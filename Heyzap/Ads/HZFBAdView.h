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

@interface HZFBAdView : HZClassProxy

typedef struct HZFBAdSize {
    CGSize size;
} HZFBAdSize;

@property (nonatomic, weak) id<HZFBAdViewDelegate> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID
                             adSize:(HZFBAdSize)adSize
                 rootViewController:(UIViewController *)viewController;

- (void)loadAd;

/**
 *  We need to be able to express that this class is a sublass of `UIView`, but I don't think this is
 *  possible. This is just a prettier way than casting to a UIView.
 *
 *  @return self, casted to a (UIView *)
 */
- (UIView *)viewProxy;

@end
