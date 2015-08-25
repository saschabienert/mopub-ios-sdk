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

/* Maps creativeType to a client for that type.*/
@property (nonatomic) NSMutableDictionary *exchangeClientsPerCreativeType;

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
        _exchangeClientsPerCreativeType = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark - Adapter Protocol
+ (BOOL)isSDKAvailable
{
    return YES;
}

- (NSError *)initializeSDK {
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

- (HZCreativeType)supportedCreativeTypes
{
    return HZCreativeTypeStatic | HZCreativeTypeIncentivized | HZCreativeTypeVideo;
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    if([self hasAdForCreativeType:creativeType]){
        HZDLog(@"HZHeyzapExchangeAdapter: Prefetch called but an ad is already available for creativeType: %@.", NSStringFromCreativeType(creativeType));
        return;
    }
    
    if(![self supportsCreativeType:creativeType]) return;
    
    HZHeyzapExchangeClient * client = [self.exchangeClientsPerCreativeType objectForKey:[self creativeTypeAsDictKey:creativeType]];
    if(client && client.state == HZHeyzapExchangeClientStateFetching){
        //already fetching
        HZDLog(@"Already fetching creativeType=%@", NSStringFromCreativeType(creativeType));
        return;
    }
    
    HZHeyzapExchangeClient *newClient = [[HZHeyzapExchangeClient alloc] init];
    [newClient setDelegate:self];
    [newClient fetchForCreativeType:creativeType];
    [self.exchangeClientsPerCreativeType setObject:newClient forKey:[self creativeTypeAsDictKey:creativeType]];
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    if(![self supportsCreativeType:creativeType]) return NO;
    
    HZHeyzapExchangeClient * client = [self.exchangeClientsPerCreativeType objectForKey:[self creativeTypeAsDictKey:creativeType]];
    if(client && client.state == HZHeyzapExchangeClientStateReady){
        return YES;
    }
    
    return NO;
}

- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    if(self.currentlyPlayingClient != nil){
        HZELog(@"HeyzapExchangeAdapter: Already showing an ad.");
        return;
    }
    
    if(![self supportsCreativeType:creativeType]) return;
    
    HZHeyzapExchangeClient * exchangeClient = [self.exchangeClientsPerCreativeType objectForKey:[self creativeTypeAsDictKey:creativeType]];
    if(!exchangeClient || exchangeClient.state != HZHeyzapExchangeClientStateReady){
        HZELog(@"HeyzapExchangeAdapter: No ad available for creativeType=%@", NSStringFromCreativeType(creativeType));
        return;
    }
    
    [exchangeClient showWithOptions:options];
}

- (NSNumber *) adScoreForCreativeType:(HZCreativeType)creativeType {
    if(![self hasAdForCreativeType:creativeType]){
        return nil;
    }
    
    HZHeyzapExchangeClient *client = [self.exchangeClientsPerCreativeType objectForKey:[self creativeTypeAsDictKey:creativeType]];
    return client.adScore;
}

- (void) setAllMediationScoresForReadyAds {
    for(NSNumber * creativeTypeKey in self.exchangeClientsPerCreativeType){
        HZCreativeType creativeType = [creativeTypeKey intValue];
        NSNumber *adScore = [self adScoreForCreativeType:creativeType];
        if(adScore){
            [self setLatestMediationScore:adScore forCreativeType:creativeType];
        }
    }
}


#pragma mark - HZHeyzapExchangeClientDelegate

- (void) client:(HZHeyzapExchangeClient *)client didFetchAdWithCreativeType:(HZCreativeType)creativeType {
    [self setError:nil forCreativeType:creativeType];
    [self.exchangeClientsPerCreativeType setObject:client forKey:[self creativeTypeAsDictKey:creativeType]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void) client:(HZHeyzapExchangeClient *)client didFailToFetchAdWithCreativeType:(HZCreativeType)creativeType error:(NSString *)error {
    [self setError:[NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}] forCreativeType:creativeType];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
    [self.exchangeClientsPerCreativeType removeObjectForKey:[self creativeTypeAsDictKey:creativeType]];
}

- (void) client:(HZHeyzapExchangeClient *)client didHaveError:(NSString *)error {
    [self setError:[NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}] forCreativeType:client.creativeType];
    [self.exchangeClientsPerCreativeType removeObjectForKey:[self creativeTypeAsDictKey:[client creativeType]]];
    self.currentlyPlayingClient = nil;
}

- (void) didStartAdWithClient:(HZHeyzapExchangeClient *)client {
    [self.delegate adapterDidShowAd:self];
    
    if(client.isWithAudio){
        [self.delegate adapterWillPlayAudio:self];
    }
    
    self.currentlyPlayingClient = client;
}

- (void) didEndAdWithClient:(HZHeyzapExchangeClient *)client successfullyFinished:(BOOL)successfullyFinished{
    self.currentlyPlayingClient = nil;
    [self.exchangeClientsPerCreativeType removeObjectForKey:[self creativeTypeAsDictKey:[client creativeType]]];
    [self setError:nil forCreativeType:client.creativeType];
    
    if(client.isWithAudio){
        [self.delegate adapterDidFinishPlayingAudio:self];
    }
    
    if(client.creativeType == HZCreativeTypeIncentivized){
        if(successfullyFinished){
            [self.delegate adapterDidCompleteIncentivizedAd:self];
        }else{
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
    
    [self.delegate adapterDidDismissAd:self];
}

- (void) adClickedWithClient:(HZHeyzapExchangeClient *)client {
    [self.delegate adapterWasClicked:self];
}


#pragma mark - Utilities

- (NSNumber *) creativeTypeAsDictKey:(HZCreativeType)creativeType {
    return [NSNumber numberWithInt:creativeType];
}

- (void) setError:(NSError *)error forCreativeType:(HZCreativeType)creativeType {
    switch(creativeType) {
        case HZCreativeTypeStatic:
            self.lastStaticError = error;
        break;
        case HZCreativeTypeIncentivized:
            self.lastIncentivizedError = error;
        break;
        case HZCreativeTypeVideo:
            self.lastVideoError = error;
        break;
        default://ignore banners, native, etc. here
        break;
    }
}

@end
