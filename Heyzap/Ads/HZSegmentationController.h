//
//  HZSegmentation.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"
#import "HZBaseAdapter.h"

@interface HZSegmentationController : NSObject

- (void) setupFromMediationStart:(nonnull NSDictionary *)startDictionary;

- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter forType:(HZAdType)adType tag:(nonnull NSString *)adTag;
- (BOOL) bannerAdapterHasAllowedAd:(nonnull HZBannerAdapter *)adapter forType:(HZAdType)adType tag:(nonnull NSString *)adTag;

- (void) recordImpressionWithType:(HZAdType)adType tag:(nonnull NSString *)tag adapter:(nonnull HZBaseAdapter *)adapter;

@end