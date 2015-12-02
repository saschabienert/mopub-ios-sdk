//
//  HZGADNativeAppInstallAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZGADNativeAppInstallAd.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADNativeAppInstallAd

+ (NSString *)hzProxiedClassName {
    return @"GADNativeAppInstallAd";
}

@dynamic headline;
@dynamic callToAction;
@dynamic icon;
@dynamic body;
@dynamic store;
@dynamic price;
@dynamic images;
@dynamic starRating;

@end
