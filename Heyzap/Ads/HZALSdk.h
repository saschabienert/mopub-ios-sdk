//
//  HZALSdk.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"
#import "HZALSdkSettings.h"

@class HZALAdService;
@class HZALTargetingData;

@interface HZALSdk : HZClassProxy

+ (HZALSdk *)sharedWithKey:(NSString *)sdkKey;
+ (HZALSdk *)sharedWithKey:(NSString *)sdkKey settings:(HZALSdkSettings *)settings;

- (void)initializeSdk;

- (HZALAdService *)adService;

+ (NSString *)version;

/**
 * Get an instance of AppLovin Targeting data. This object contains
 * targeting values that could be provided to AppLovin for better
 * advertisement performance.
 *
 * @return Current targeting data. Guaranteed not to be null.
 */
@property (strong, nonatomic, readonly) HZALTargetingData* targetingData;

@end
