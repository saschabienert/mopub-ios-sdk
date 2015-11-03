//
//  HZIMBannerDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZIMBanner;
@class HZIMRequestStatus;

@protocol HZIMBannerDelegate <NSObject>

/**
 * Notifies the delegate that the banner has finished loading
 */
-(void)bannerDidFinishLoading:(HZIMBanner*)banner;
/**
 * Notifies the delegate that the banner has failed to load with some error.
 */
-(void)banner:(HZIMBanner*)banner didFailToLoadWithError:(HZIMRequestStatus*)error;
/**
 * Notifies the delegate that the banner was interacted with.
 */
-(void)banner:(HZIMBanner*)banner didInteractWithParams:(NSDictionary*)params;
/**
 * Notifies the delegate that the user would be taken out of the application context.
 */
-(void)userWillLeaveApplicationFromBanner:(HZIMBanner*)banner;
/**
 * Notifies the delegate that the banner would be presenting a full screen content.
 */
-(void)bannerWillPresentScreen:(HZIMBanner*)banner;
/**
 * Notifies the delegate that the banner has finished presenting screen.
 */
-(void)bannerDidPresentScreen:(HZIMBanner*)banner;
/**
 * Notifies the delegate that the banner will start dismissing the presented screen.
 */
-(void)bannerWillDismissScreen:(HZIMBanner*)banner;
/**
 * Notifies the delegate that the banner has dismissed the presented screen.
 */
-(void)bannerDidDismissScreen:(HZIMBanner*)banner;
/**
 * Notifies the delegate that the user has completed the action to be incentivised with.
 */
-(void)banner:(HZIMBanner*)banner rewardActionCompletedWithRewards:(NSDictionary*)rewards;

@end
