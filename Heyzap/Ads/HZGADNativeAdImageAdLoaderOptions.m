//
//  HZGADNativeAdImageAdLoaderOptions.m
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZGADNativeAdImageAdLoaderOptions.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADNativeAdImageAdLoaderOptions

+ (NSString *)hzProxiedClassName {
    return @"GADNativeAdImageAdLoaderOptions";
}

@dynamic disableImageLoading;
@dynamic shouldRequestMultipleImages;
@dynamic preferredImageOrientation;

@end
