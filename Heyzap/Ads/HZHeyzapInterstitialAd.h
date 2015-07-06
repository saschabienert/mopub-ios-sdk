//
//  HZHeyzapInterstitialAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZShowOptions.h"

@protocol HZAdsDelegate;

@interface HZHeyzapInterstitialAd : NSObject

/**
 *  Shows an interstitial ad configured with the given options
 *
 * @param auctionType Heyzap auction type for this show
 * @param options HZShowOptions object containing configuration
 */
+ (void) showForAuctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options;

#pragma mark - Callbacks

/** Sets the delegate to receive the messages listed in the `HZAdsDelegate` protocol.
 
 @param delegate The object to receive the callbacks.
 */
+ (void) setDelegate: (id<HZAdsDelegate>) delegate;

/**
 *  Fetches an interstitial ad for the given tag with an optional completion handler
 *
 *  @param completion A block called when the ad is fetched or failed to fetch. result contains whether or not the fetch was successful, and if not, error contains the reason why.
 */
+ (void) fetchForAuctionType:(HZAuctionType)auctionType withCompletion: (void (^)(BOOL result, NSError *error))completion;


/**
 *  Whether or not an ad is available to show for the given tag.
 *
 *  @param tag An identifier for the location of the ad which you can use to disable the ad from your dashboard.
 *
 *  @return If the ad was available
 */
+ (BOOL) isAvailableForTag: (NSString *) tag auctionType:(HZAuctionType)auctionType;

/** Dismisses the current ad, if visible. */
+ (void) hide;


#pragma mark - Private methods

+ (void) setCreativeID:(int)creativeID;
+ (void)forceTestCreative:(BOOL)forceTestCreative;
+ (void)setCreativeType:(NSString *)creativeType;

+ (void)showAdWithOptions:(NSDictionary *)options;

@end
