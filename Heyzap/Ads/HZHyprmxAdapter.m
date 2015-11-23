//
//  HZHyprmxAdapter.m
//  Heyzap
//
//  Created by Daniel Rhodes on 5/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHyprmxAdapter.h"
#import "HZDictionaryUtils.h"
#import "HZMediationConstants.h"
#import "HeyzapMediation.h"
#import "HeyzapAds.h"
#import "HZDevice.h"
#import "HZAdsManager.h"
#import "HZInitMacros.h"
#import <AdSupport/AdSupport.h>
#import "HZBaseAdapter_Internal.h"

@interface HZHyprmxAdapter()
@property (nonatomic, strong) NSString *distributorID;
@property (nonatomic, strong) NSString *propertyID;
@property (nonatomic) BOOL isAdReady;
@property (nonatomic) BOOL isCheckingAvailability;
@end

@implementation HZHyprmxAdapter

+ (instancetype)sharedAdapter {
    static HZHyprmxAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZHyprmxAdapter alloc] init];
        proxy.forwardingDelegate = [HZAdapterDelegate new];
        proxy.forwardingDelegate.adapter = proxy;
    });
    return proxy;
}

- (void)loadCredentials {
    self.distributorID = [HZDictionaryUtils
                          objectForKey:@"distributor_id"
                          ofClass:[NSString class]
                          dict:self.credentials];
    
    self.propertyID = [HZDictionaryUtils objectForKey:@"property_id"
                                              ofClass:[NSString class]
                                                 dict:self.credentials];
}

- (BOOL) hasNecessaryCredentials {
    return self.distributorID != nil && self.propertyID != nil;
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable {
    return ([HZHYPRManager hzProxiedClassIsAvailable] && [HZDevice hzSystemVersionIsGreaterOrEqualTo: @"7.0"]);
}

+ (NSString *)name {
    return HZNetworkHyprMX;
}

+ (NSString *) humanizedName {
    return @"HyprMX";
}

+ (NSString *)sdkVersion {
    return [[HZHYPRManager sharedManager] versionString];
}

- (NSError *)internalInitializeSDK {
    if (![self hasNecessaryCredentials]) {
        NSMutableArray *erroredCredentials = [NSMutableArray array];
        if (!self.distributorID){
            [erroredCredentials addObject:@"Distributor ID"];
        }
        
        if (!self.propertyID) {
            [erroredCredentials addObject:@"Property ID"];
        }
        
        RETURN_ERROR_UNLESS(NO, ([NSString stringWithFormat:@"%@ needs a Distributor ID and a Property ID set up on your dashboard, you're missing these: [%@]", [self humanizedName], [erroredCredentials componentsJoinedByString:@", "]]));
    }
    
    NSString *adID = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    
    [HZHYPRManager disableAutomaticPreloading];
    HZDLog(@"Initializing HyprMX with Distributor ID: %@ and Property ID: %@",self.distributorID, self.propertyID);
    [[HZHYPRManager sharedManager] initializeWithDistributorId:self.distributorID
                                                    propertyId:self.propertyID
                                                        userId:adID];
    return nil;
}

- (HZCreativeType)supportedCreativeTypes {
    return HZCreativeTypeIncentivized;
}

- (BOOL)internalHasAdWithMetadata:(id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    if (!self.isCheckingAvailability) {
        self.isCheckingAvailability = YES;
        // the block we pass to get the result is called asynchronously, so we save the last result
        // we've received and return that from this method, and at the same time request an update.
        [[HZHYPRManager sharedManager] checkInventory:^(BOOL isOfferReady) {
            self.isAdReady = isOfferReady;
            self.isCheckingAvailability = NO;
        }];
    }
    
    return self.isAdReady;
}

- (void)internalPrefetchAdWithOptions:(HZAdapterFetchOptions *)options {
    HZAssert(self.distributorID, @"Need a Distributor ID by this point");
    HZAssert(self.propertyID, @"Need a Property ID by this point");

    [[HZHYPRManager sharedManager] preloadContent];
}

- (void)internalShowAdWithOptions:(HZShowOptions *)options{
    [[HZHYPRManager sharedManager] checkInventory:^(BOOL isOfferReady) {
        self.isAdReady = isOfferReady;
        if (isOfferReady) {
            [self.delegate adapterDidShowAd:self];
            [self.delegate adapterWillPlayAudio:self];
            
            [[HZHYPRManager sharedManager] displayOffer:^(BOOL completed, id offer) {
                self.isAdReady = NO;
                if (options.creativeType == HZCreativeTypeIncentivized) {
                    if (completed) {
                        [self.delegate adapterDidCompleteIncentivizedAd: self];
                    } else {
                        [self.delegate adapterDidFailToCompleteIncentivizedAd: self];
                    }
                }
                [self.delegate adapterDidFinishPlayingAudio:self];
                [self.delegate adapterDidDismissAd:self];
            }];
        } else {
            [self.delegate adapterDidFailToShowAd:self error:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"HYPRMx said it did not have an ad to show right now."}]];
        }
    }];
}

@end
