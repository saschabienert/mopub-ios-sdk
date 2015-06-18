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
 *  This delegate responds to the callbacks relating to incentivized ads in addition to the callbacks in HZAppLovinDelegate.
 */
@interface HZIncentivizedAppLovinDelegate : HZAppLovinDelegate <HZALAdRewardDelegate>
@end
