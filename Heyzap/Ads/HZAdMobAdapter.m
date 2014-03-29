//
//  HZAdMobProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdMobAdapter.h"
#import "HZGADInterstitial.h"
#import "HZGADRequest.h"
#import <UIKit/UIKit.h>
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"

@interface HZAdMobAdapter() <HZGADInterstitialDelegate>

@property (nonatomic, strong) HZGADInterstitial *currentInterstitial;

@property (nonatomic, strong) NSString *adUnitID;

@end

@implementation HZAdMobAdapter

+ (instancetype)sharedInstance
{
    static HZAdMobAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZAdMobAdapter alloc] init];
    });
    return proxy;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    NSParameterAssert(credentials);
    
    NSError *error;
    NSString *const adUnitID = [HZDictionaryUtils objectForKey:@"ad_unit_id" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    [[self sharedInstance] setAdUnitID:adUnitID];
    
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZGADInterstitial hzProxiedClassIsAvailable] && [HZGADRequest hzProxiedClassIsAvailable];
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial;
}

- (void)prefetch
{
    if (self.currentInterstitial
        && !self.currentInterstitial.hasBeenUsed
        && !self.lastError) {
        // If we have an interstitial already out fetching, don't start up a re-fetch.
        return;
    }
    NSLog(@"Prefetch called for admob");
    
    self.currentInterstitial = [[HZGADInterstitial alloc] init];
    self.currentInterstitial.adUnitID = @"ca-app-pub-3919373204654131/8414896602";
    self.currentInterstitial.delegate = self;
    
    HZGADRequest *request = [HZGADRequest request];
    
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    
    [self.currentInterstitial loadRequest:[HZGADRequest request]];
}

+ (NSString *)name
{
    return kHZAdapterAdMob;
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

#pragma mark - Delegate callbacks

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"GADInterstitialDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)interstitial:(HZGADInterstitial *)ad didFailToReceiveAdWithError:(HZGADRequestError *)error
{
    self.lastError = [NSError errorWithDomain:kHZMediationDomain
                                         code:1
                                     userInfo:@{kHZMediatorNameKey: @"AdMob",
                                                NSUnderlyingErrorKey: error}];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    self.lastError = nil;
}

@end
