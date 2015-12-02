//
//  HZGADNativeContentAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZGADNativeContentAd.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADNativeContentAd

+ (NSString *)hzProxiedClassName {
    return @"GADNativeContentAd";
}

@dynamic headline;
@dynamic body;
@dynamic images;
@dynamic logo;
@dynamic callToAction;
@dynamic advertiser;

@end
