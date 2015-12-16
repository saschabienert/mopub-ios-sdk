//
//  HZAdapterFetchOptions.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/19/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HZAdapterFetchOptions : NSObject <HZMediationAdAvailabilityDataProviderProtocol>

@property (nonatomic) HZCreativeType creativeType;
@property (nonatomic, nonnull) NSString *tag;
@property (nonatomic, nullable) NSString *placementIDOverride;
@property (nonatomic, nullable) UIViewController *presentingViewController;
@property (nonatomic, nonnull) NSNumber *uniqueNativeAdsToFetch;
@property (nonatomic, nonnull) NSArray<NSString *> *admobNativeAdTypes;
@property (nonatomic) HZAdMobNativeAdImageOrientation admobPreferredImageOrientation;

- (nonnull instancetype)initWithCreativeType:(HZCreativeType)creativeType
                                         tag:(nonnull NSString *)tag
                         placementIDOverride:(nullable NSString *)placementIDOverride
                    presentingViewController:(nullable UIViewController *)presentingViewController
                      uniqueNativeAdsToFetch:(nullable NSNumber *)uniqueNativeAdsToFetch
                          admobNativeAdTypes:(nullable NSArray *)admobNativeAdTypes
               admobPreferredImageOrienation:(HZAdMobNativeAdImageOrientation)admobImageOrientation NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)initWithCreativeType:(HZCreativeType)creativeType
                         placementIDOverride:(nullable NSString *)placementIDOverride
                                fetchOptions:(nonnull HZFetchOptions *)fetchOptions;


@end
