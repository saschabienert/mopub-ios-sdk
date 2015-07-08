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

/* Maps adType to a client for that type.*/
@property (nonatomic) NSMutableDictionary *exchangeClientsPerAdType;

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
        _exchangeClientsPerAdType = [[NSMutableDictionary alloc] init];
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
    return HZAdTypeInterstitial | HZAdTypeIncentivized | HZAdTypeVideo;
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
    
    HZHeyzapExchangeClient * client = [self.exchangeClientsPerAdType objectForKey:[self adTypeAsDictKey:type]];
    if(client && client.state == HZHeyzapExchangeClientStateFetching){
        //already fetching
        HZDLog(@"Already fetching adType=%lu.",(unsigned long)type);
        return;
    }
    
    HZHeyzapExchangeClient *newClient = [[HZHeyzapExchangeClient alloc] init];
    [newClient setDelegate:self];
    [newClient fetchForAdType:type];
    [self.exchangeClientsPerAdType setObject:newClient forKey:[self adTypeAsDictKey:type]];
}

- (BOOL)hasAdForType:(HZAdType)type
{
    if(![self supportedAdFormats] & type){
        return false;
    }
    HZHeyzapExchangeClient * client = [self.exchangeClientsPerAdType objectForKey:[self adTypeAsDictKey:type]];
    if(client && client.state == HZHeyzapExchangeClientStateReady){
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
    
    HZHeyzapExchangeClient * exchangeClient = [self.exchangeClientsPerAdType objectForKey:[self adTypeAsDictKey:type]];
    if(!exchangeClient || exchangeClient.state != HZHeyzapExchangeClientStateReady){
        HZELog(@"HeyzapExchangeAdapter: No ad available for that type.")
        return;
    }
    
    [exchangeClient showWithOptions:options];
}

- (NSNumber *) adScoreForAdType:(HZAdType)adType {
    if(![self hasAdForType:adType]){
        return nil;
    }
    
    HZHeyzapExchangeClient *client = [self.exchangeClientsPerAdType objectForKey:[self adTypeAsDictKey:adType]];
    return client.adScore;
}


#pragma mark - HZHeyzapExchangeClientDelegate

- (void) client:(HZHeyzapExchangeClient *)client didFetchAdWithType:(HZAdType)adType {
    [self setError:nil forType:adType];
    [self.exchangeClientsPerAdType setObject:client forKey:[self adTypeAsDictKey:adType]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void) client:(HZHeyzapExchangeClient *)client didFailToFetchAdWithType:(HZAdType)adType error:(NSString *)error{
    [self setError:[NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}] forType:client.adType];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
    [self.exchangeClientsPerAdType removeObjectForKey:[self adTypeAsDictKey:adType]];
}

- (void) client:(HZHeyzapExchangeClient *)client didHaveError:(NSString *)error {
    [self setError:[NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}] forType:client.adType];
    [self.exchangeClientsPerAdType removeObjectForKey:[self adTypeAsDictKey:[client adType]]];
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
    [self.exchangeClientsPerAdType removeObjectForKey:[self adTypeAsDictKey:[client adType]]];
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
