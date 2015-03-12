//
//  HZBannerAdOptions.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZBannerAdOptions : NSObject

extern NSString * const kHZBannerNetworkFacebook;
extern NSString * const kHZBannerNetworkAdMob;
extern NSString * const kHZBannerNetworkiAds;

/**
 *  @name Facebook Banner Sizes
 */

/**
 *  A fixed size 320x50 pt banner. Corresponds to kFBAdSize320x50.
 */
extern NSString * const kHZFacebookBannerSize320x50;

/**
 *  A banner 50 pts in height whose width expands to fill its containing view. Corresponds to kFBAdSizeHeight50Banner.
 */
extern NSString * const kHZFacebookBannerSizeHeight50FlexibleWidth;

/**
 *  A banner 90 pts in height whose width expands to fill its containing view. Corresponds to kFBAdSizeHeight90Banner.
 */
extern NSString * const kHZFacebookBannerSizeHeight90FlexibleWidth;

@end
