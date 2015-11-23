//
//  HZAdapterFetchOptions.m
//  Heyzap
//
//  Created by Maximilian Tagher on 11/19/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAdapterFetchOptions.h"
#import "HZFetchOptions_Private.h"

@implementation HZAdapterFetchOptions

- (nonnull instancetype)initWithCreativeType:(HZCreativeType)creativeType
                                         tag:(nonnull NSString *)tag
                         placementIDOverride:(nullable NSString *)placementIDOverride
                    presentingViewController:(nullable UIViewController *)presentingViewController
                      uniqueNativeAdsToFetch:(nullable NSNumber *)uniqueNativeAdsToFetch
                          admobNativeAdTypes:(nullable NSArray *)admobNativeAdTypes
               admobPreferredImageOrienation:(HZAdMobNativeAdImageOrientation)admobImageOrientation {
    self = [super init];
    if (self) {
        _creativeType = creativeType;
        _tag = tag;
        _placementIDOverride = placementIDOverride;
        _presentingViewController = presentingViewController;
        _uniqueNativeAdsToFetch = uniqueNativeAdsToFetch;
        _admobNativeAdTypes = admobNativeAdTypes;
        _admobPreferredImageOrientation = admobImageOrientation;
    }
    return self;
}

- (nonnull instancetype)initWithCreativeType:(HZCreativeType)creativeType
                         placementIDOverride:(nullable NSString *)placementIDOverride
                                fetchOptions:(HZFetchOptions *)fetchOptions {
    return [self initWithCreativeType:creativeType tag:fetchOptions.tag
                  placementIDOverride:placementIDOverride
             presentingViewController:fetchOptions.presentingViewController
               uniqueNativeAdsToFetch:fetchOptions.uniqueNativeAdsToFetch
                   admobNativeAdTypes:fetchOptions.admobNativeAdTypes
        admobPreferredImageOrienation:fetchOptions.admobPreferredImageOrientation];
}

- (instancetype)init NS_UNAVAILABLE {
    return nil;
}

@end
