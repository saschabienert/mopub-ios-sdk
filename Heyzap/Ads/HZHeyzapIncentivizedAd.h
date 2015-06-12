//
//  HZHeyzapIncentivizedAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/4/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZShowOptions.h"

@protocol HZIncentivizedAdDelegate;

@interface HZHeyzapIncentivizedAd : NSObject

+ (void)setDelegate:(id<HZIncentivizedAdDelegate>)delegate;

/** Shows an incentivized video ad configured with the given options
 *
 * @param auctionType Heyzap auction type for this show
 * @param options HZShowOptions object containing configuration
 */
+ (void)showForAuctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options;

/**
 *  Fetches an incentivized video ad from Heyzap.
 *
 *  @param completion A block called when the video is fetched or fails to fetch. `result` states whether the fetch was sucessful; the error object describes the issue, if there was one.
 */
+ (void)fetchForAuctionType:(HZAuctionType)auctionType completion:(void (^)(BOOL result, NSError *error))completion;

/** Dismisses the current ad, if visible. */
+ (void)hide;

/**
 *  Whether or not an incentivized ad is ready to show for the particular tag.
 *
 *  @param tag Tag name describing the location or context for the ad to be shown.
 *
 *  @return If the video is ready to show
 */
+ (BOOL)isAvailableForTag:(NSString *)tag auctionType:(HZAuctionType)auctionType;

/**
 *  (Optional) As a layer of added security, you can specify an identifier for the user. You can opt to receive a server-to-server callback with the provided userIdentifier.
 *
 *  @param userIdentifier Any unique identifier, like a username, email, or ID that your server-side database uses.
 */
+ (void) setUserIdentifier: (NSString *) userIdentifier;


+ (void) setCreativeID: (int) creativeID;

@end
