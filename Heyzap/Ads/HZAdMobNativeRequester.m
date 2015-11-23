//
//  HZAdMobNativeRequester.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAdMobNativeRequester.h"
#import "HZGADRequest.h"
#import "HZGADAdLoader.h"

#import "HZGADNativeAppInstallAdLoaderDelegate.h"
#import "HZGADNativeContentAdLoaderDelegate.h"
#import "HZGADRequestError.h"

#import "HZGADNativeContentAd.h"
#import "HZGADNativeAppInstallAd.h"
#import "HZQueue.h"

#import "HZAdMobNativeAppInstallAdAdapter.h"
#import "HZAdMobNativeContentAdAdapter.h"
#import "HZAdapterFetchOptions.h"
#import "HZGADNativeAdImageAdLoaderOptions.h"


@interface HZAdMobNativeRequester() <HZGADNativeAppInstallAdLoaderDelegate, HZGADNativeContentAdLoaderDelegate>

@property (nonatomic, readonly) NSString *nativeAdUnitID;
@property (nonatomic, readonly) HZBaseAdapter *parentAdapter;

@property (nonatomic) HZQueue *ads;

@property (nonatomic) NSError *lastNativeError;
@property (nonatomic) NSMutableArray *loaders;

@end

@implementation HZAdMobNativeRequester

- (instancetype)initWithNativeAdUnitID:(NSString *)nativeAdUnitID parentAdapter:(HZBaseAdapter *)parentAdapter {
    HZParameterAssert(nativeAdUnitID);
    self = [super init];
    if (self) {
        _parentAdapter = parentAdapter;
        _nativeAdUnitID = nativeAdUnitID;
        _ads = [[HZQueue alloc] init];
        _loaders = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init NS_UNAVAILABLE {
    return nil;
}

- (NSUInteger)adCount {
    return [self.ads count];
}

- (void)fetchNative:(HZAdapterFetchOptions *)options {
    NSParameterAssert([NSThread isMainThread]);
    
    HZGADNativeAdImageAdLoaderOptions *loaderOptions = [[HZGADNativeAdImageAdLoaderOptions alloc] init];
    loaderOptions.disableImageLoading = YES;
    loaderOptions.preferredImageOrientation = (HZGADNativeAdImageAdLoaderOptionsOrientation)options.admobPreferredImageOrientation;
    
    HZGADAdLoader *loader = [[HZGADAdLoader alloc] initWithAdUnitID:self.nativeAdUnitID
                                                 rootViewController:options.presentingViewController
                                                            adTypes:options.admobNativeAdTypes
                                                            options:@[loaderOptions]];
    loader.delegate = self;
    [loader loadRequest:[HZGADRequest request]];
    [self.loaders addObject:loader];
}

- (void)adLoader:(HZGADAdLoader *)adLoader didFailToReceiveAdWithError:(HZGADRequestError *)error {
    HZELog(@"GADAdLoader: %@ failed to receive native ad with error: %@",adLoader, error);
    NSError *castedError = (NSError *)error;
    self.lastNativeError = castedError;
    [self.loaders removeObjectIdenticalTo:adLoader];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    NSString *protocolName = NSStringFromProtocol(aProtocol);
    if ([protocolName isEqualToString:@"GADNativeContentAdLoaderDelegate"]) {
        return YES;
    } else if ([protocolName isEqualToString:@"GADNativeAppInstallAdLoaderDelegate"]) {
        return YES;
    } else if ([protocolName isEqualToString:@"GADAdLoaderDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)adLoader:(HZGADAdLoader *)adLoader didReceiveNativeContentAd:(HZGADNativeContentAd *)nativeContentAd {
    HZDLog(@"Received native content ad from AdMob");
    [self.ads enqueue:nativeContentAd];
    [self.loaders removeObjectIdenticalTo:adLoader];
}

- (void)adLoader:(HZGADAdLoader *)adLoader didReceiveNativeAppInstallAd:(HZGADNativeAppInstallAd *)nativeAppInstallAd {
    HZDLog(@"Received native app install ad from AdMob");
    [self.ads enqueue:nativeAppInstallAd];
    [self.loaders removeObjectIdenticalTo:adLoader];
}

- (nullable HZNativeAdAdapter *)getNativeOrError:(NSError *  _Nonnull * _Nullable)error metadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider {
    id ad = [self.ads dequeue];
    
    if (ad) {
        NSString *const className = NSStringFromClass([ad class]);
        if ([className isEqualToString:@"GADNativeAppInstallAd"]) {
            return [[HZAdMobNativeAppInstallAdAdapter alloc] initWithAppInstallAd:ad parentAdapter:self.parentAdapter];
        } else if ([className isEqualToString:@"GADNativeContentAd"]) {
            return [[HZAdMobNativeContentAdAdapter alloc] initWithContentAd:ad parentAdapter:self.parentAdapter];
        }
        return nil;
    } else if (self.lastNativeError) {
        *error = self.lastNativeError;
        return nil;
    } else {
        return nil;
    }
}

@end
