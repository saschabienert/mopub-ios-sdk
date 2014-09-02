//
//  HZMetricsKey.h
//  Heyzap
//
//  Created by Maximilian Tagher on 8/18/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  This class is used by HZMetrics as an immutable dictionary key.
 */
@interface HZMetricsKey : NSObject <NSCopying>

/**
 *  The tag of the ad, guaranteed to be non-nil.
 */
@property (nonatomic, readonly) NSString *tag;
/**
 *  The type of the ad being shown (interstitial, incentivized, video). Guaranteed to be non-nil.
 */
@property (nonatomic, readonly) NSString *adType;

/**
 *  Initializer.
 *
 *  @param tag    The tag of the ad; required property.
 *  @param adType The tag of the ad; required property.
 *
 *  @return The metrics key.
 */
- (instancetype)initWithTag:(NSString *)tag type:(NSString *)adType;

@end
