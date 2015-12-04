//
//  HZIMInterstitial.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/19/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@protocol HZIMInterstitialDelegate;

@interface HZIMInterstitial : HZClassProxy

@property (nonatomic, strong) NSDictionary *extras;

/**
 * Initialize an Interstitial with the given PlacementId
 * @param placementId The placementId for loading the interstitial
 * @param delegate The delegate to receive callbacks
 */
-(instancetype)initWithPlacementId:(long long)placementId delegate:(id<HZIMInterstitialDelegate>)delegate;
/**
 * Loads an Interstitial
 */
-(void)load;
/**
 * To query if the interstitial is ready to be shown
 */
-(BOOL)isReady;
/**
 * Displays the interstitial on the screen
 * @param view controller, this view controller will be used to present interestitial.
 */
-(void)showFromViewController:(UIViewController *)viewController;

@end
