//
//  HZHeyzapProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZMediationAdapter.h"

@interface HZHeyzapAdapter : NSObject <HZMediationAdapter>

@property (nonatomic, strong) NSError *lastError;

@end
