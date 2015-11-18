//
//  HZIMInterstitialDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/19/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZIMInterstitial;
@class HZIMRequestStatus;

@protocol HZIMInterstitialDelegate <NSObject>

@optional
/**
 * Notifies the delegate that the interstitial has finished loading
 */
-(void)interstitialDidFinishLoading:(HZIMInterstitial*)interstitial;
/**
 * Notifies the delegate that the interstitial has failed to load with some error.
 */
-(void)interstitial:(HZIMInterstitial*)interstitial didFailToLoadWithError:(HZIMRequestStatus*)error;
/**
 * Notifies the delegate that the interstitial would be presented.
 */
-(void)interstitialWillPresent:(HZIMInterstitial*)interstitial;
/**
 * Notifies the delegate that the interstitial has been presented.
 */
-(void)interstitialDidPresent:(HZIMInterstitial *)interstitial;
/**
 * Notifies the delegate that the interstitial has failed to present with some error.
 */
-(void)interstitial:(HZIMInterstitial*)interstitial didFailToPresentWithError:(HZIMRequestStatus*)error;
/**
 * Notifies the delegate that the interstitial will be dismissed.
 */
-(void)interstitialWillDismiss:(HZIMInterstitial*)interstitial;
/**
 * Notifies the delegate that the interstitial has been dismissed.
 */
-(void)interstitialDidDismiss:(HZIMInterstitial*)interstitial;
/**
 * Notifies the delegate that the interstitial has been interacted with.
 */
-(void)interstitial:(HZIMInterstitial*)interstitial didInteractWithParams:(NSDictionary*)params;
/**
 * Notifies the delegate that the user has performed the action to be incentivised with.
 */
-(void)interstitial:(HZIMInterstitial*)interstitial rewardActionCompletedWithRewards:(NSDictionary*)rewards;
/**
 * Notifies the delegate that the user will leave application context.
 */
-(void)userWillLeaveApplicationFromInterstitial:(HZIMInterstitial*)interstitial;


@end