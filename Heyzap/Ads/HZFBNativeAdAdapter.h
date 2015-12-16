//
//  HZFBNativeAdAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZNativeAdAdapter.h"

@class HZFBNativeAd;
@class HZMediatedNativeAdIndividualAdOptions;

@interface HZFBNativeAdAdapter : HZNativeAdAdapter

- (instancetype)initWithNativeAd:(HZFBNativeAd *)nativeAd parentAdapter:(HZBaseAdapter *)parentAdapter;

@end
