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

/**
 *  Because Vungle makes no differentiation between having an incentivized ad and having a video ad, we just store any error in a property shared between the ad types.
 */
@property (nonatomic, strong) NSError *lastError;
@property (nonatomic) BOOL isShowingIncentivized;

@property (nonatomic) NSMutableArray * exchangeClients;
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

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    HZHeyzapExchangeClient *client = [[HZHeyzapExchangeClient alloc] init];
    [client setDelegate:self];
    [client fetchForAdType:type];
    [self.exchangeClients addObject:client]; // keeps a strong ref to client until we get a callback

}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    if(![self supportedAdFormats] & type){
        return false;
    }
    
    if([self.adTypeExchangeClients objectForKey:[self adTypeAsDictKey:type]]){
        return true;
    }
    
    return false;
}

- (NSError *)lastErrorForAdType:(HZAdType)adType
{
    return self.lastError;
}

- (void)clearErrorForAdType:(HZAdType)adType
{
    self.lastError = nil;
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    if(self.currentlyPlayingClient != nil){
        NSLog(@"ERROR: client already showing ad.");
        return;
    }
    
    HZHeyzapExchangeClient * exchangeClient = [self.adTypeExchangeClients objectForKey:[self adTypeAsDictKey:type]];
    if(!exchangeClient){
        return;
    }
    
    [exchangeClient play];
}


- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"HZHeyzapExchangeClientDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}


#pragma mark - Banners

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return [[HZHeyzapExchangeBannerAdapter alloc] initWithAdUnitID:nil options:options reportingDelegate:reportingDelegate parentAdapter:self];
}
- (BOOL)hasBannerCredentials {
    return YES;//monroe: ?
}

#pragma mark - HZHeyzapExchangeClientDelegate

- (void) client:(HZHeyzapExchangeClient *)client didFetchAdWithType:(HZAdType)adType {
    [self.adTypeExchangeClients setObject:client forKey:[self adTypeAsDictKey:adType]];
    [self.exchangeClients removeObject:client];
}

- (void) client:(HZHeyzapExchangeClient *)client didFailToFetchAdWithType:(HZAdType)adType {
    [self.exchangeClients removeObject:client];
}

- (void) client:(HZHeyzapExchangeClient *)client didHaveError:(NSString *)error {
    NSLog(@"monroe: clientDidHaveError: %@", error);
    self.lastError = [NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}];
}

- (void) didStartAdWithClient:(HZHeyzapExchangeClient *)client {
    if(client.isWithAudio){
        [self.delegate adapterWillPlayAudio:self];
    }
    
    [self.delegate adapterDidShowAd:self];
    
    self.currentlyPlayingClient = client;    
}

- (void) didEndAdWithClient:(HZHeyzapExchangeClient *)client successfullyFinished:(BOOL)successfullyFinished{
    if(self.currentlyPlayingClient != client){
        NSLog(@"ERROR: client that didEndAd is not currentlyPlayingClient!");
    }
    
    if(client.isWithAudio){
        [self.delegate adapterDidFinishPlayingAudio:self];
    }
    
    if(client.isIncentivized){
        if(successfullyFinished){
            [self.delegate adapterDidCompleteIncentivizedAd:self];
        }else{
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
    
    [self.delegate adapterDidDismissAd:self];
    
    self.currentlyPlayingClient = nil;
}

- (void) adClickedWithClient:(HZHeyzapExchangeClient *)client {
    [self.delegate adapterWasClicked:self];
}

#pragma mark - Utilities

- (NSNumber *) adTypeAsDictKey:(HZAdType)adType {
    return [NSNumber numberWithInt:adType];
}

@end
