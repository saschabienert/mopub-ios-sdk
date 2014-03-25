//
//  HZAdMobProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdMobProxy.h"
#import "HZGADInterstitial.h"
#import "HZGADRequest.h"
#import <UIKit/UIKit.h>

@interface HZAdMobProxy()

@property (nonatomic, strong) HZGADInterstitial *currentInterstitial;

@end

@implementation HZAdMobProxy

+ (instancetype)sharedInstance
{
    static HZAdMobProxy *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZAdMobProxy alloc] init];
    });
    return proxy;
}

- (void)prefetch
{
    NSLog(@"Prefetch called for admob");
    
    self.currentInterstitial = [[HZGADInterstitial alloc] init];
    self.currentInterstitial.adUnitID = @"ca-app-pub-3919373204654131/8414896602";
    
    HZGADRequest *request = [HZGADRequest request];
    
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    
    [self.currentInterstitial loadRequest:[HZGADRequest request]];
}

- (BOOL)hasAd
{
    BOOL hasAd = self.currentInterstitial.isReady;
    NSLog(@"Admob has ad = %i",hasAd);
    return hasAd;
}

- (void)showAd
{
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [self.currentInterstitial presentFromRootViewController:vc];
}

@end
