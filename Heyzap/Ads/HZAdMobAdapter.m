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

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZAdMobAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZAdMobAdapter alloc] init];
    });
    return proxy;
}

#pragma mark - Adapter Protocol

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

+ (NSString *)name
{
    return kHZAdapterAdMob;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    return [self supportedAdFormats] & type && self.currentInterstitial.isReady;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    NSAssert(self.adUnitID, @"Need an ad unit ID by this point");
    if (self.currentInterstitial
        && !self.currentInterstitial.hasBeenUsed
        && !self.lastInterstitialError) {
        // If we have an interstitial already out fetching, don't start up a re-fetch.
        return;
    }
    
    self.currentInterstitial = [[HZGADInterstitial alloc] init];
    self.currentInterstitial.adUnitID = self.adUnitID;
    self.currentInterstitial.delegate = self;
    
    HZGADRequest *request = [HZGADRequest request];
    
    request.testDevices = @[ GAD_SIMULATOR_ID ];
    
    [self.currentInterstitial loadRequest:[HZGADRequest request]];
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
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
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain
                                         code:1
                                     userInfo:@{kHZMediatorNameKey: @"AdMob",
                                                NSUnderlyingErrorKey: error}];
    self.currentInterstitial = nil;
}

- (void)interstitialDidDismissScreen:(HZGADInterstitial *)ad
{
    [self.delegate adapterDidDismissAd:self];
    self.currentInterstitial = nil;
}

// As far as I can tell, this means a click.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad
{
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    self.lastInterstitialError = nil;
}

@end
