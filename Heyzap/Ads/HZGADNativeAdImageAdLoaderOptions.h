//
//  HZGADNativeAdImageAdLoaderOptions.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

/// Native ad image orientation preference.
typedef NS_ENUM(NSInteger, HZGADNativeAdImageAdLoaderOptionsOrientation) {
    HZGADNativeAdImageAdLoaderOptionsOrientationAny,       ///< No orientation preference.
    HZGADNativeAdImageAdLoaderOptionsOrientationPortrait,  ///< Prefer portrait images.
    HZGADNativeAdImageAdLoaderOptionsOrientationLandscape  ///< Prefer landscape images.
};

@interface HZGADNativeAdImageAdLoaderOptions : HZClassProxy

- (instancetype)init;

@property(nonatomic, assign) BOOL disableImageLoading;

/// Indicates if multiple images should be loaded for each asset. Defaults to NO.
@property(nonatomic, assign) BOOL shouldRequestMultipleImages;

/// Indicates preferred image orientation. Defaults to
/// GADNativeAdImageAdLoaderOptionsOrientationAny.
@property(nonatomic, assign) HZGADNativeAdImageAdLoaderOptionsOrientation preferredImageOrientation;

@end
