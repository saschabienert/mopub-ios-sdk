//
//  HZALSdk.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZALAdService;

@interface HZALSdk : HZClassProxy

+ (HZALSdk *)sharedWithKey:(NSString *)sdkKey;

- (void)initializeSdk;

- (HZALAdService *)adService;

+ (NSString *)version;

@end
