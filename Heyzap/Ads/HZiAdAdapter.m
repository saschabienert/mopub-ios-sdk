//
//  HZiAdAdapter.m
//  Heyzap
//
//  Created by Daniel Rhodes on 3/4/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZiAdAdapter.h"

@import iAd;

#import "HZMediationConstants.h"

@interface HZiAdAdapter()<ADInterstitialAdDelegate>

@property (nonatomic, strong) ADInterstitialAd *interstitialAd;

@end

@implementation HZiAdAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZiAdAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[HZiAdAdapter alloc] init];
    });
    return adapter;
}

#pragma mark - HZ methods

+ (BOOL)isSDKAvailable
{
    return YES;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials {
    return nil;
}

+ (NSString *)name
{
    return kHZAdapteriAd;
}

+ (NSString *)humanizedName
{
    return kHZAdapteriAdHumanized;
}

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat: @"%@", [UIDevice currentDevice].systemVersion];
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag {
    if (type != HZAdTypeInterstitial) {
        return;
    }
    
    if (self.interstitialAd == nil) {
        self.interstitialAd = [[ADInterstitialAd alloc] init];
        self.interstitialAd.delegate = self;
    }
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if (type != HZAdTypeInterstitial) {
        return NO;
    }
    
    if (self.interstitialAd != nil) {
        return self.interstitialAd.loaded;
    }
    
    return NO;
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag {
    if (type != HZAdTypeInterstitial) {
        return;
    }
    
    
    BOOL success = NO;
    if ([[self.delegate viewControllerForPresentingAd] respondsToSelector: @selector(requestInterstitialAdPresentation)]) {
        success = [[self.delegate viewControllerForPresentingAd] requestInterstitialAdPresentation];
    }
    
    if (!success) {
        [self.interstitialAd presentFromViewController: [self.delegate viewControllerForPresentingAd]];
    }
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

#pragma mark - ADInterstitialAdDelegate

- (void)interstitialAdWillLoad:(ADInterstitialAd *)interstitialAd {
    
}

- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd {
    self.lastInterstitialError = nil;
}

- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd: self];
}

- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd
                   willLeaveApplication:(BOOL)willLeave {
    [self.delegate adapterWasClicked: self];
    return YES;
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd:self];
}

- (void)interstitialAd:(ADInterstitialAd *)interstitialAd
      didFailWithError:(NSError *)error {
    
    
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain
                                                     code:1
                                                 userInfo:@{kHZMediatorNameKey: @"iAd",
                                                            NSUnderlyingErrorKey: error}];
    self.interstitialAd = nil;
}



@end
