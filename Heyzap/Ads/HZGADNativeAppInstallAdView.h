//
//  HZGADNativeAppInstallAdView.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZGADNativeAppInstallAd;

@interface HZGADNativeAppInstallAdView : HZClassProxy

- (instancetype)init;

/// This property must point to the native app install ad object rendered by this ad view.
@property(nonatomic, strong) HZGADNativeAppInstallAd *nativeAppInstallAd;

// Weak references to your ad view's asset views.
@property(nonatomic, weak) IBOutlet UIView *headlineView;
@property(nonatomic, weak) IBOutlet UIView *callToActionView;
@property(nonatomic, weak) IBOutlet UIView *iconView;
@property(nonatomic, weak) IBOutlet UIView *bodyView;
@property(nonatomic, weak) IBOutlet UIView *storeView;
@property(nonatomic, weak) IBOutlet UIView *priceView;
@property(nonatomic, weak) IBOutlet UIView *imageView;
@property(nonatomic, weak) IBOutlet UIView *starRatingView;

@end
