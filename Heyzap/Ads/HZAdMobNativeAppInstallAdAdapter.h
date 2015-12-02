//
//  HZAdMobNativeAppInstallAdAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAbstractAdMobNativeAdAdapter.h"

@class HZGADNativeAppInstallAd;

NS_ASSUME_NONNULL_BEGIN

@interface HZAdMobNativeAppInstallAdAdapter : HZAbstractAdMobNativeAdAdapter

- (instancetype)initWithAppInstallAd:(HZGADNativeAppInstallAd *)appInstallAd parentAdapter:(HZBaseAdapter *)parentAdapter;

@end

NS_ASSUME_NONNULL_END