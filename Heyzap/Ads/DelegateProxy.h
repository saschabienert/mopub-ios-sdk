//
//  DelegateProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/2/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HeyzapAds.h"

@interface DelegateProxy : NSProxy  <HZAdsDelegate, HZIncentivizedAdDelegate>

@property (nonatomic, weak) id forwardingTarget;

- (instancetype)init;

@end
