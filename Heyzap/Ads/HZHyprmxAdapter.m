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

@interface HZHyprmxAdapter()
@property (nonatomic, strong) NSString *distributorID;
@property (nonatomic, strong) NSString *propertyID;
@end

@implementation HZHyprmxAdapter

+ (instancetype)sharedInstance {
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

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable {
    return ([HZHYPRManager hzProxiedClassIsAvailable] && [HZDevice hzSystemVersionIsGreaterOrEqualTo: @"7.0"]);
}

+ (NSString *)name {
    return HZNetworkHyperMX;
}

+ (NSString *) humanizedName {
    return @"HyprMX";
}

+ (NSString *)sdkVersion {
    return [[HZHYPRManager sharedManager] versionString];
}

- (NSError *)initializeSDK {
    RETURN_ERROR_IF_NIL(self.distributorID, @"distributorID");
    
    NSString *adID = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    
    [HZHYPRManager disableAutomaticPreloading];
    HZDLog(@"Initializing HyprMX with Distributor ID: %@ and Property ID: %@",self.distributorID, self.propertyID);
    [[HZHYPRManager sharedManager] initializeWithDistributorId:self.distributorID
                                                    propertyId:self.propertyID
                                                        userId:adID];
    return nil;
}

- (HZAdType)supportedAdFormats {
    return HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return YES;
}

static BOOL wasReady = NO;
- (BOOL)hasAdForType:(HZAdType)type {
    [[HZHYPRManager sharedManager] checkInventory:^(BOOL isOfferReady) {
        wasReady = isOfferReady;
    }];
    
    return wasReady;
}

- (void)prefetchForType:(HZAdType)type {
    HZAssert(self.distributorID, @"Need a Distributor ID by this point");
    HZAssert(self.propertyID, @"Need a Property ID by this point");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[HZHYPRManager sharedManager] preloadContent];
    });
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options {
    HZHyprmxAdapter *bSelf = self;
    
    [[HZHYPRManager sharedManager] checkInventory:^(BOOL isOfferReady) {
        wasReady = isOfferReady;
        if (isOfferReady) {
            
            [self.delegate adapterDidShowAd:self];
            [self.delegate adapterWillPlayAudio:self];
            
            [[HZHYPRManager sharedManager] displayOffer:^(BOOL completed, id offer) {
                wasReady = NO;
                if (type == HZAdTypeIncentivized) {
                    if (completed) {
                        [bSelf.delegate adapterDidCompleteIncentivizedAd: bSelf];
                    } else {
                        [bSelf.delegate adapterDidFailToCompleteIncentivizedAd: bSelf];
                    }
                }
                [self.delegate adapterDidFinishPlayingAudio:self];
                [self.delegate adapterDidDismissAd:self];
            }];
        }
    }];
}

@end
