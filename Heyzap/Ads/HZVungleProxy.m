//
//  HZVungleProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZVungleProxy.h"
#import "HZVGVunglePub.h"
#import <UIKit/UIKit.h>

@implementation HZVungleProxy

+ (instancetype)sharedInstance
{
    static HZVungleProxy *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZVungleProxy alloc] init];
    });
    return proxy;
}

- (void)prefetch
{
    // Vungle autoprefetches
}

- (BOOL)hasAd
{
    return [HZVGVunglePub adIsAvailable];
}

- (void)showAd
{
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [HZVGVunglePub playModalAd:vc animated:YES];
}

@end
