//
//  HZHeyzapNativeAdAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZNativeAdAdapter.h"

@class HZMediatedNativeAdIndividualAdOptions;

NS_ASSUME_NONNULL_BEGIN

@interface HZHeyzapNativeAdAdapter : HZNativeAdAdapter

- (instancetype)initWithNativeAd:(HZNativeAd *)nativeAd
                   parentAdapter:(HZBaseAdapter *)parentAdapter;

@end

NS_ASSUME_NONNULL_END