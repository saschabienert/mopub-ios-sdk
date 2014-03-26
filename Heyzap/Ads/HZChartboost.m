//
//  HZChartboostClassProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/24/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZChartboost.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HZChartboost

@dynamic appId;
@dynamic appSignature;
@dynamic delegate;

+ (NSString *)hzProxiedClassName
{
    return @"Chartboost";
}

@end
