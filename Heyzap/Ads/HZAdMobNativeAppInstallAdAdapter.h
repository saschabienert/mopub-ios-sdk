//
//  HZAdMobNativeAppInstallAdAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAbstractAdMobNativeAdAdapter.h"

@class HZGADNativeAppInstallAd;

@interface HZAdMobNativeAppInstallAdAdapter : HZAbstractAdMobNativeAdAdapter

- (instancetype)initWithAppInstallAd:(HZGADNativeAppInstallAd *)appInstallAd parentAdapter:(HZBaseAdapter *)parentAdapter;

@end
