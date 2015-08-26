//
//  HZSegmentation.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/3/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZCreativeType.h"
#import "HZBaseAdapter.h"

@interface HZSegmentationController : NSObject

/**
 *  Reads current segments from /start dictionary and loads them from HZImpressionHistory asynchronously.
 */
- (void) setupFromMediationStart:(nonnull NSDictionary *)startDictionary;

/**
 *  Returns YES if current segmentation rules make it pointless to fetch any ads at this time from the given adapter, or NO if it's possible for some ads to get through the current segmentation filters from the given adapter.
 */
- (BOOL) isAdapterCompletelyDisabledRightNow:(nonnull HZBaseAdapter *)adapter;

/**
 *  Returns YES if the given adapter both has an ad and is allowed to show one based on the current segmentation rules, NO otherwise.
 */
- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter forCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)adTag;
/**
 *  Returns YES if the given banner adapter both has an ad and is allowed to show one based on the current segmentation rules, NO otherwise.
 */
- (BOOL) bannerAdapterHasAllowedAd:(nonnull HZBannerAdapter *)adapter tag:(nonnull NSString *)adTag;

/**
 *  Call this method with every impression. It will update HZImpressionHistory and all of the currently loaded segments.
 */
- (void) recordImpressionWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag adapter:(nonnull HZBaseAdapter *)adapter;

/**
 *  Deletes the HZImpressionHistory and reloads all segments from the newly-cleared history. Returns YES if the delete worked, NO otherwise.
 */
- (BOOL) clearImpressionHistory;

@end