//
//  HZALAdRewardDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/14/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZALAd;

@protocol HZALAdRewardDelegate <NSObject>

/*
 * If you are using reward validation for incentivized videos, this method
 * will be invoked if we contacted AppLovin successfully. This means that we believe the
 * reward is legitimate and should be awarded. Please note that ideally you should refresh the
 * user's balance from your server at this point to prevent tampering with local data on jailbroken devices.
 *
 * The response NSDictionary will typically includes the keys "currency" and "amount", which point to NSStrings containing the name and amount of the virtual currency to be awarded.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad didSucceedWithResponse:(NSDictionary *)response;

/*
 * This method will be invoked if we were able to contact AppLovin, but the user has already received
 * the maximum number of coins you allowed per day in the web UI.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad didExceedQuotaWithResponse:(NSDictionary *)response;

/*
 * This method will be invoked if the AppLovin server rejected the reward request.
 * This would usually happen if the user fails to pass an anti-fraud check.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad wasRejectedWithResponse:(NSDictionary *)response;

/*
 * This method will be invoked if were unable to contact AppLovin, so no ping will be heading to your server.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad didFailWithError:(NSInteger)responseCode;

/*
 * This method will be invoked if the user chooses 'no' when asked if they want to view a rewarded video.
 */
- (void)userDeclinedToViewAd:(HZALAd *)ad;

@end
