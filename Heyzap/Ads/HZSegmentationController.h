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
 *  If YES, rules will be checked and impressions will be recorded. If NO, all segment rules will pass and no impressions will be recorded.
 */
@property (nonatomic) BOOL enabled;

/**
 *  Reads current segments from /start dictionary and loads them from HZImpressionHistory asynchronously.
 */
- (void) setupFromMediationStart:(nonnull NSDictionary *)startDictionary completion:(nullable void (^)(BOOL finished))completion;

/**
 *  Returns YES if the given adapter both has an ad and is allowed to show one based on the current segmentation rules, NO otherwise.
 */
- (BOOL) adapterHasAllowedAd:(nonnull HZBaseAdapter *)adapter forCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)adTag;

/**
 *  Returns YES if the given adapter is allowed to show an ad based on the current segmentation rules, NO otherwise. This method does NOT check if the adapter has an ad for the given creativeType.
 */
- (BOOL) allowAdapter:(nonnull HZBaseAdapter *)adapter toShowAdForCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)adTag;

/**
 *  Returns YES if the given banner adapter both has an ad and is allowed to show one based on the current segmentation rules, NO otherwise.
 */
- (BOOL) bannerAdapterHasAllowedAd:(nonnull HZBannerAdapter *)adapter tag:(nonnull NSString *)adTag;

/**
 *  Returns YES if the given banner adapter is allowed to show an ad based on the current segmentation rules, NO otherwise. This method does NOT check if the banner adapter has an ad.
 */
- (BOOL) allowBannerAdapter:(nonnull HZBannerAdapter *)bannerAdapter toShowAdForTag:(nonnull NSString *)adTag;

/**
 *  Call this method with every impression. It will update HZImpressionHistory and all of the currently loaded segments.
 */
- (void) recordImpressionWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag adapter:(nonnull HZBaseAdapter *)adapter;

/**
 *  Deletes the HZImpressionHistory and reloads all segments from the newly-cleared history. Returns YES to the completion block if the delete worked, NO otherwise.
 */
- (void) clearImpressionHistoryWithCompletion:(nullable void (^)(BOOL successful))completion;

@end