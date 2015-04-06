//
//  TestAppConfiguration.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "PersistentTestAppConfiguration.h"
@import UIKit;

@implementation PersistentTestAppConfiguration

#pragma mark - Initialization

+ (instancetype)sharedConfiguration {
    static PersistentTestAppConfiguration *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PersistentTestAppConfiguration alloc] init];
    });
    return instance;
}

#pragma mark - Auto-Prefetch

NSString * const kHZAutoPrefetchSettingKey = @"kHZAutoPrefetchSettingKey";

- (void)setAutoPrefetch:(BOOL)autoPrefetch {
    [[NSUserDefaults standardUserDefaults] setBool:autoPrefetch forKey:kHZAutoPrefetchSettingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)autoPrefetch {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kHZAutoPrefetchSettingKey];
}

@end
