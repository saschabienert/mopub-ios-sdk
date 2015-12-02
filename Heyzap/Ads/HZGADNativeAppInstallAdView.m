//
//  HZGADNativeAppInstallAdView.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZGADNativeAppInstallAdView.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADNativeAppInstallAdView

@dynamic nativeAppInstallAd;
@dynamic headlineView;
@dynamic callToActionView;
@dynamic iconView;
@dynamic bodyView;
@dynamic storeView;
@dynamic priceView;
@dynamic imageView;
@dynamic starRatingView;

+ (NSString *)hzProxiedClassName {
    return @"GADNativeAppInstallAdView";
}

@end
