//
//  HZIncentivizedAppLovinDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/14/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAppLovinDelegate.h"
#import "HZALAdRewardDelegate.h"

/**
 *  This delegate also responds to the callbacks relating to incentivized ads. I'm not 100% sure this is necessary—depends on if the adLoad delegate handles things like fraud detection, and the adDisplay delegate handles things like the user saying 'no' to wanting an incentivized ad.
 */
@interface HZIncentivizedAppLovinDelegate : HZAppLovinDelegate <HZALAdRewardDelegate>

@property (nonatomic) BOOL rewardValidationSucceeded;

@end
