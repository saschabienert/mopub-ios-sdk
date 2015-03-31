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
#import "HZMetrics.h"
#import "HZMetricsAdStub.h"
#import "HZAdMobBannerAdapter.h"

@interface HZAdMobAdapter() <HZGADInterstitialDelegate>

@property (nonatomic, strong) HZGADInterstitial *currentInterstitial;

@property (nonatomic, strong) NSString *adUnitID;
@property (nonatomic, strong) NSString *bannerAdUnitID;

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
    NSString *adUnitID = [HZDictionaryUtils objectForKey:@"ad_unit_id" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    // Nullable property.
    NSString *bannerAdUnitId = [HZDictionaryUtils hzObjectForKey:@"banner_ad_unit_id" ofClass:[NSString class] withDict:credentials];
    
    HZAdMobAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        [[self sharedInstance] setAdUnitID:adUnitID];
        [[self sharedInstance] setBannerAdUnitID:bannerAdUnitId];
    }
    
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


+ (NSString *)humanizedName
{
    return kHZAdapterAdMobHumanized;
}

+ (NSString *)sdkVersion {
    return [HZGADRequest sdkVersion];
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    return [self supportedAdFormats] & type && self.currentInterstitial.isReady;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeBanner;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
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

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    [self.currentInterstitial presentFromRootViewController:options.viewController];

    self.metricsStub = [[HZMetricsAdStub alloc] initWithTag:options.tag adUnit:NSStringFromAdType(type)];
    [[HZMetrics sharedInstance] logTimeSinceShowAdFor:kShowAdTimeTillAdIsDisplayedKey withProvider:self.metricsStub network:[self name]];
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
    [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterDidDismissAd:self];
    self.currentInterstitial = nil;
}

// As far as I can tell, this means a click.
- (void)interstitialWillLeaveApplication:(HZGADInterstitial *)ad
{
    [[HZMetrics sharedInstance] logMetricsEvent:kAdClickedKey value:@1 withProvider:self.metricsStub network:[self name]];
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialDidReceiveAd:(HZGADInterstitial *)ad
{
    self.lastInterstitialError = nil;
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZAdMobBannerAdapter alloc] initWithAdUnitID:self.bannerAdUnitID options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

- (BOOL)hasBannerCredentials {
    return self.bannerAdUnitID != nil;
}

@end
