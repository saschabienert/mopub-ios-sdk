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

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials {
    HZParameterAssert(credentials);
    NSError *error;
    
    NSString *distributorID = [HZDictionaryUtils
                             objectForKey:@"distributor_id"
                             ofClass:[NSString class]
                             dict:credentials
                             error:&error];
    
    CHECK_CREDENTIALS_ERROR(error);
    
    // Nullable
    NSString *const propertyID = [HZDictionaryUtils hzObjectForKey:@"property_id"
                                                                  ofClass:[NSString class]
                                                                 withDict:credentials];
    
    HZHyprmxAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        adapter.distributorID = distributorID;
        adapter.propertyID = propertyID;
        
        [[self sharedInstance] initializeWithDistributorID: distributorID andPropertyID: propertyID];
        
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackInitialized forNetwork: [self name]];
    }
    
    return nil;
}

- (void) initializeWithDistributorID: (NSString *) distributorID andPropertyID: (NSString *) propertyID {
    HZParameterAssert(propertyID);
    HZParameterAssert(distributorID);
    
    NSString *adID = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    
    [HZHYPRManager disableAutomaticPreloading];
    [[HZHYPRManager sharedManager] initializeWithDistributorId:distributorID
                                                    propertyId:propertyID
                                                        userId:adID];
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

// Disabled since it takes a long time to show an ad on unity and ane sdks
// Override
- (unsigned long long)showAdTimeout {
    if ([[[HZAdsManager sharedManager] framework] isEqualToString:@"unity3d"]) {
        return 0;
        
    } else {
        return [super showAdTimeout];
    }
}

@end
