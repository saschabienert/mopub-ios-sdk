//
//  HZAdMobProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdMobProxy.h"
#import "GADInterstitial.h"

@interface HZAdMobProxy()

@property (nonatomic, strong) GADInterstitial *currentInterstitial;

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
    self.currentInterstitial = [[GADInterstitial alloc] init];
    self.currentInterstitial.adUnitID = @"ca-app-pub-3919373204654131/8414896602";
    
    GADRequest *request = [GADRequest request];
    
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    
    [self.currentInterstitial loadRequest:[GADRequest request]];
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
