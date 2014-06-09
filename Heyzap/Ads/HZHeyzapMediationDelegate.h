//
//  HZHeyzapMediationDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/18/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZHeyzapAdapter.h"
#import "HeyzapAds.h"

/**
 *  Because Heyzap delegate methods use the same selectors, we need separate objects to receive the selectors + differentiate between ad types.
 */
@interface HZHeyzapMediationDelegate : NSObject <HZIncentivizedAdDelegate>

- (id)initWithAdType:(HZAdType)adType delegate:(id<HZHeyzapDelegateReceiver>)delegate;

@end
