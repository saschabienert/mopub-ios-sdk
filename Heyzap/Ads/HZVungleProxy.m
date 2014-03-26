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
#import "HZVGStatusData.h"
#import "MediationConstants.h"

@interface HZVungleProxy() <HZVGVunglePubDelegate>

@end

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

- (id)init
{
    self = [super init];
    if (self) {
        [HZVGVunglePub setDelegate:self];
    }
    return self;
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

- (void)vungleStatusUpdate:(HZVGStatusData *)statusData
{
    if (statusData.status != HZVGStatusOkay) {
        self.lastError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey: @"Vungle"}];
    } else {
        self.lastError = nil;
    }
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"VGVunglePubDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

@end
