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

@property (nonatomic, strong, readonly) NSString *tag;
@property (nonatomic, readonly) HZAdType adType;
@property (nonatomic, readonly) BOOL hasBeenShown;

- (instancetype)initWithAdType:(HZAdType)type tag:(NSString *)tag;

- (instancetype)sessionKeyAfterShowing;

@end
