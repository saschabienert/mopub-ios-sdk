//
//  HZMediationSession.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

/**
 *  Session keys encapsulate the unique data for a request. By preventing
 */
@interface HZMediationSessionKey : NSObject <NSCopying>

@property (nonatomic, readonly) HZAdType adType;

- (instancetype)initWithAdType:(HZAdType)type;

@end
