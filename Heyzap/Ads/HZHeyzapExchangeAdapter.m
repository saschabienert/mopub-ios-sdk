//
//  HZHeyzapExchangeAdapter.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/25/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZHeyzapExchangeAdapter.h"

#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZBannerAd.h"

#import "HZBannerAdOptions.h"
#import "HZBannerAdOptions_Private.h"
#import "HeyzapMediation.h"
#import "HeyzapAds.h"
#import "HZSKVASTViewController.h"
#import "HZHeyzapExchangeClient.h"
#import "HZHeyzapExchangeBannerAdapter.h"

@interface HZHeyzapExchangeAdapter()<HZHeyzapExchangeClientDelegate>
/* Just keeps reference to clients during their fetches. They will be added to the dict adTypeExchangeClients once they fetch (that's when we're certain of their adType)*/
@property (nonatomic) NSMutableArray * exchangeClients;
/* Maps adType to a client that has already fetched an ad for that type.*/
@property (nonatomic) NSMutableDictionary *adTypeExchangeClients;

@property (nonatomic) HZHeyzapExchangeClient *currentlyPlayingClient;
@end

@implementation HZHeyzapExchangeAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static HZHeyzapExchangeAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZHeyzapExchangeAdapter alloc] init];
    });
    return proxy;
}

- (instancetype) init {
    self = [super init];
    if(self){
        _exchangeClients = [[NSMutableArray alloc] init];
        _adTypeExchangeClients = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark - Adapter Protocol
+ (BOOL)isSDKAvailable
{
    return YES;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials{
    [HZHeyzapExchangeAdapter sharedInstance].credentials = @{};//exchange does not have credentials, but nil checks later will think there was a failure w/o this
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    return nil;
}

+ (NSString *)name
{
    return HZNetworkHeyzapExchange;
}

+ (NSString *)humanizedName
{
    return kHZAdapterHeyzapExchangeHumanized;
}

+ (NSString *)sdkVersion {
    return nil;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeIncentivized | HZAdTypeVideo | HZAdTypeBanner;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

- (void)prefetchForType:(HZAdType)type
{
    if([self hasAdForType:type]){
        HZDLog(@"Prefetch called but an ad is already available.");
        return;
    }
    
    HZHeyzapExchangeClient *client = [[HZHeyzapExchangeClient alloc] init];
    [client setDelegate:self];
    [client fetchForAdType:type];
    [self.exchangeClients addObject:client]; // keeps a strong ref to client until we get a callback
}

- (BOOL)hasAdForType:(HZAdType)type
{
    if(![self supportedAdFormats] & type){
        return false;
    }
    
    if([self.adTypeExchangeClients objectForKey:[self adTypeAsDictKey:type]]){
        return true;
    }
    
    return false;
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    if(self.currentlyPlayingClient != nil){
        HZELog(@"HeyzapExchangeAdapter: Already showing an ad.");
        return;
    }
    
    HZHeyzapExchangeClient * exchangeClient = [self.adTypeExchangeClients objectForKey:[self adTypeAsDictKey:type]];
    if(!exchangeClient){
        HZELog(@"HeyzapExchangeAdapter: No ad available for that type.")
        return;
    }
    
    [exchangeClient showWithOptions:options];
}


#pragma mark - Banners

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZHeyzapExchangeBannerAdapter alloc] initWithAdUnitID:nil options:options reportingDelegate:reportingDelegate parentAdapter:self];
}

- (BOOL)hasBannerCredentials {
    return YES;
}

#pragma mark - HZHeyzapExchangeClientDelegate

- (void) client:(HZHeyzapExchangeClient *)client didFetchAdWithType:(HZAdType)adType {
    [self setError:nil forType:adType];
    [self.adTypeExchangeClients setObject:client forKey:[self adTypeAsDictKey:adType]];
    [self.exchangeClients removeObject:client];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void) client:(HZHeyzapExchangeClient *)client didFailToFetchAdWithType:(HZAdType)adType error:(NSString *)error{
    [self setError:[NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}] forType:client.adType];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
    [self.exchangeClients removeObject:client];
}

- (void) client:(HZHeyzapExchangeClient *)client didHaveError:(NSString *)error {
    [self setError:[NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}] forType:client.adType];
    [self.adTypeExchangeClients removeObjectForKey:[self adTypeAsDictKey:[client adType]]];
    [self.exchangeClients removeObject:client];
    self.currentlyPlayingClient = nil;
}

- (void) didStartAdWithClient:(HZHeyzapExchangeClient *)client {
    [self.delegate adapterDidShowAd:self];
    
    if(client.isWithAudio){
        [self.delegate adapterWillPlayAudio:self];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioStarting forNetwork: [self name]];
    }
    
    self.currentlyPlayingClient = client;
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackShow forNetwork: [self name]];
}

- (void) didEndAdWithClient:(HZHeyzapExchangeClient *)client successfullyFinished:(BOOL)successfullyFinished{
    self.currentlyPlayingClient = nil;
    [self.adTypeExchangeClients removeObjectForKey:[self adTypeAsDictKey:[client adType]]];
    [self setError:nil forType:client.adType];
    
    if(client.isWithAudio){
        [self.delegate adapterDidFinishPlayingAudio:self];
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAudioFinished forNetwork: [self name]];
    }
    
    if(client.isIncentivized){
        if(successfullyFinished){
            [self.delegate adapterDidCompleteIncentivizedAd:self];
            [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultComplete forNetwork: [self name]];
        }else{
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
            [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackIncentivizedResultIncomplete forNetwork: [self name]];
        }
    }
    
    [self.delegate adapterDidDismissAd:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackHide forNetwork: [self name]];
}

- (void) adClickedWithClient:(HZHeyzapExchangeClient *)client {
    [self.delegate adapterWasClicked:self];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackClick forNetwork: [self name]];
}


#pragma mark - Utilities

- (NSNumber *) adTypeAsDictKey:(HZAdType)adType {
    return [NSNumber numberWithInt:adType];
}

- (void) setError:(NSError *)error forType:(HZAdType)type {
    switch(type) {
        case HZAdTypeInterstitial:
            self.lastInterstitialError = error;
        break;
        case HZAdTypeIncentivized:
            self.lastIncentivizedError = error;
        break;
        case HZAdTypeVideo:
            self.lastVideoError = error;
        break;
        default://ignore banners here
        break;
    }
}

@end
