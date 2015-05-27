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
    return [HZHYPRManager hzProxiedClassIsAvailable];
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
    
    [[HZHYPRManager sharedManager] initializeWithDistributorId:distributorID
                                                    propertyId:propertyID
                                                        userId:adID];
}

- (HZAdType)supportedAdFormats {
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeIncentivized;
}

- (BOOL)isVideoOnlyNetwork {
    return YES;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag {
    __block BOOL successful;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[HZHYPRManager sharedManager] checkInventory:^(BOOL isOfferReady) {
        successful = isOfferReady;
        dispatch_semaphore_signal(semaphore);
     }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return successful;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag {
    HZAssert(self.distributorID, @"Need a Distributor ID by this point");
    HZAssert(self.propertyID, @"Need a Property ID by this point");
    
//    if (type != HZAdTypeInterstitial) {
//        // only prefetch if they want an interstitial
//        return;
//    }
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options {
    __block HZHyprmxAdapter *bSelf = self;
    [[HZHYPRManager sharedManager] displayOffer:^(BOOL completed, HYPROffer *offer) {
        if (type == HZAdTypeIncentivized) {
            if (completed) {
                [bSelf.delegate adapterDidCompleteIncentivizedAd: bSelf];
            } else {
                [bSelf.delegate adapterDidFailToCompleteIncentivizedAd: bSelf];
            }
        }
    }];
}

#pragma mark - Facebook Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return YES;
//    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"FBInterstitialAdDelegate"]) {
//        return YES;
//    } else {
//        return [super conformsToProtocol:aProtocol];
//    }
}
                

@end
