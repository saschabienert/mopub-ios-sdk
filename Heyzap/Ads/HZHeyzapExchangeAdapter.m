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
#import "HZBaseAdapter_Internal.h"

@interface HZHeyzapExchangeAdapter()<HZHeyzapExchangeClientDelegate>

@property (nonatomic) NSMutableDictionary<HZCreativeTypeObject *, HZHeyzapExchangeClient *> *exchangeClientsPerCreativeType;

@property (nonatomic) HZHeyzapExchangeClient *currentlyPlayingClient;
@end

@implementation HZHeyzapExchangeAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
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

- (NSError *)internalInitializeSDK {
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

- (void)internalPrefetchAdWithOptions:(HZAdapterFetchOptions *)options
{
    HZHeyzapExchangeClient * client = [self.exchangeClientsPerCreativeType objectForKey:@(options.creativeType)];
    if(client && client.state == HZHeyzapExchangeClientStateFetching){
        //already fetching
        HZDLog(@"Already fetching creativeType=%@", NSStringFromCreativeType(options.creativeType));
        return;
    }
    
    HZHeyzapExchangeClient *newClient = [[HZHeyzapExchangeClient alloc] init];
    [self.exchangeClientsPerCreativeType setObject:newClient forKey:@(options.creativeType)];
    [newClient setDelegate:self];
    [newClient fetchForCreativeType:options.creativeType];
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider
{
    HZHeyzapExchangeClient * client = [self.exchangeClientsPerCreativeType objectForKey:@(dataProvider.creativeType)];
    if(client && client.state == HZHeyzapExchangeClientStateReady){
        return YES;
    }
    
    return NO;
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options
{
    HZHeyzapExchangeClient * exchangeClient = [self.exchangeClientsPerCreativeType objectForKey:@(options.creativeType)];
    if(!exchangeClient || exchangeClient.state != HZHeyzapExchangeClientStateReady){
        HZELog(@"HeyzapExchangeAdapter: No ad available for creativeType=%@", NSStringFromCreativeType(options.creativeType));
        [self.delegate adapterDidFailToShowAd:self error:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ adapter was asked to show an ad of creativeType: %@, but it doesn't have one.", [[self class] humanizedName], NSStringFromCreativeType(options.creativeType)]}]];
        return;
    }
    
    [exchangeClient showWithOptions:options];
}

- (NSNumber *) adScoreForCreativeType:(HZCreativeType)creativeType {
    if(![self hasAdWithMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:creativeType]]){
        return nil;
    }
    
    HZHeyzapExchangeClient *client = [self.exchangeClientsPerCreativeType objectForKey:@(creativeType)];
    return client.adScore;
}

- (void) setAllMediationScoresForReadyAds {
    for(HZCreativeTypeObject *creativeTypeKey in self.exchangeClientsPerCreativeType){
        HZCreativeType creativeType = hzCreativeTypeFromObject(creativeTypeKey);
        NSNumber *adScore = [self adScoreForCreativeType:creativeType];
        if(adScore){
            [self setLatestMediationScore:adScore forCreativeType:creativeType];
        }
    }
}


#pragma mark - HZHeyzapExchangeClientDelegate

- (void) client:(HZHeyzapExchangeClient *)client didFetchAdWithCreativeType:(HZCreativeType)creativeType {
    [self clearLastFetchErrorForAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:creativeType]];
    [self.exchangeClientsPerCreativeType setObject:client forKey:@(creativeType)];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
}

- (void) client:(HZHeyzapExchangeClient *)client didFailToFetchAdWithCreativeType:(HZCreativeType)creativeType error:(NSString *)error {
    [self setLastFetchError:[NSError errorWithDomain: @"com.heyzap.sdk.ads.exchange.error" code: 10 userInfo: @{NSLocalizedDescriptionKey: error}] forAdsWithMatchingMetadata:[[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:creativeType]];
    [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
    [self.exchangeClientsPerCreativeType removeObjectForKey:@(creativeType)];
}

- (void) client:(HZHeyzapExchangeClient *)client didHaveError:(NSString *)error {
    HZELog(@"Exchange client had error: %@", error);
    [self.exchangeClientsPerCreativeType removeObjectForKey:@([client creativeType])];
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
    [self.exchangeClientsPerCreativeType removeObjectForKey:@([client creativeType])];
    
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


@end
