//
//  DelegateProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/2/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HeyzapAds.h"

/**
 *  Sending delegate messages is a pain since you have to check if the delegate `respondsToSelector:` everywhere. This class transparently forwards selectors to the given `forwardingTarget` if they respond to the selector, otherwise it swallows them, eliminating the `respondsToSelector:` checks.
 */
@interface DelegateProxy : NSProxy  <HZAdsDelegate, HZIncentivizedAdDelegate>

@property (nonatomic, weak) id forwardingTarget;

- (instancetype)init;

@end
