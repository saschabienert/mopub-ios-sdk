//
//  HZVungleProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZVungleAdapter.h"
#import "HZVGVunglePub.h"
#import <UIKit/UIKit.h>
#import "HZVGStatusData.h"
#import "MediationConstants.h"

@interface HZVungleAdapter() <HZVGVunglePubDelegate>

@end

@implementation HZVungleAdapter

+ (instancetype)sharedInstance
{
    static HZVungleAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZVungleAdapter alloc] init];
    });
    return proxy;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeIncentivized | HZAdTypeVideo;
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
