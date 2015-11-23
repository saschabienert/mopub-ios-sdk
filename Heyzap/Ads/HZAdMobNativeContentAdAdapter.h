//
//  HZAdMobNativeContentAdAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAbstractAdMobNativeAdAdapter.h"

@class HZGADNativeContentAd;

@interface HZAdMobNativeContentAdAdapter : HZAbstractAdMobNativeAdAdapter

- (instancetype)initWithContentAd:(HZGADNativeContentAd *)contentAd parentAdapter:(HZBaseAdapter *)parentAdapter;

@end
