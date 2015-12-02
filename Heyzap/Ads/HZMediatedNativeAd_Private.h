//
//  Header.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediatedNativeAd.h"

@class HZNativeAdAdapter;

NS_ASSUME_NONNULL_BEGIN

@interface HZMediatedNativeAd ()

- (instancetype)initWithAdapter:(HZNativeAdAdapter *)adapter tag:(NSString *)tag;

@end

NS_ASSUME_NONNULL_END