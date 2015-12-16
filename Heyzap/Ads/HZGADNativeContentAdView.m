//
//  HZGADNativeContentAdView.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZGADNativeContentAdView.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADNativeContentAdView

@dynamic nativeContentAd;
@dynamic headlineView;
@dynamic bodyView;
@dynamic imageView;
@dynamic logoView;
@dynamic callToActionView;
@dynamic advertiserView;

+ (NSString *)hzProxiedClassName {
    return @"GADNativeContentAdView";
}

@end
