//
//  HZHeyzapVideoAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZShowOptions.h"

@protocol HZAdsDelegate;

@interface HZHeyzapVideoAd : NSObject

/**
 *  Shows a video for a given tag, if available.
 *
 * @param auctionType Heyzap auction type for this show
 * @param options HZShowOptions object containing configuration
 */
+ (void) showForAuctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options;

/**
 *  Fetches a new ad for the given tag.
 *
 *  @param completion A block called when the video is fetched or fails to fetch. `result` states whether the fetch was sucessful; the error object describes the issue, if there was one.
 *
 */
+ (void) fetchForAuctionType:(HZAuctionType)auctionType withCompletion: (void (^)(BOOL result, NSError *error))completion;

/**
 *  Whether or not the video is ready to show for the given tag
 *
 *  @param tag An identifier for the location of the ad which you can use to disable the ad from your dashboard.
 *
 *  @return Whether or not the video is ready to show for the given tag
 */
+ (BOOL) isAvailableForTag: (NSString *) tag auctionType:(HZAuctionType)auctionType;

/**
 *  Dismisses the current ad, if visible.
 */
+ (void) hide;

# pragma mark - Testing;
+ (void) setCreativeID:(int)creativeID;

@end
