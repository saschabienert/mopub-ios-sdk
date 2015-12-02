//
//  HZFBNativeAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZFBNativeAd.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZFBNativeAd

@dynamic placementID;
@dynamic title;
@dynamic subtitle;
@dynamic callToAction;
@dynamic icon;
@dynamic coverImage;
@dynamic body;
@dynamic mediaCachePolicy;
@dynamic delegate;
@dynamic adValid;

+ (NSString *)hzProxiedClassName {
    return @"FBNativeAd";
}

@end
