//
//  HZGADNativeAdImage.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZGADNativeAdImage.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZGADNativeAdImage

@dynamic imageURL;
@dynamic scale;

+ (NSString *)hzProxiedClassName {
    return @"GADNativeAdImage";
}

@end
