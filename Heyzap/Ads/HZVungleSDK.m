//
//  HZVungleSDK.m
//  Heyzap
//
//  Created by David Stumm on 8/28/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZVungleSDK.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZVungleSDK

@dynamic userData;
@dynamic delegate;
@dynamic assetLoader;
@dynamic incentivizedAlertText;
@dynamic muted;
@dynamic globalOptions;

+ (NSString *)hzProxiedClassName
{
    return @"VungleSDK";
}

@end
