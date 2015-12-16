//
//  HZIMSdk.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/19/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

// TODO: Maybe move this to a constants file like InMobi uses
typedef NS_ENUM(NSInteger, HZIMSDKLogLevel) {
    kHZIMSDKLogLevelNone,
    kHZIMSDKLogLevelError,
    kHZIMSDKLogLevelDebug
};

@class CLLocation;

@interface HZIMSdk : HZClassProxy

/**
 *  Initialize the sdk. This must be called before any other API for the SDK is used.
 * @param accountID account id obtained from the InMobi portal.
 */
+(void)initWithAccountID:(NSString *)accountID;

/**
 * Use this to get the version of the SDK.
 * @return The version of the SDK.
 */
+(NSString *)getVersion;

/**
 * Set the log level for SDK's logs
 * @param desiredLogLevel The desired level of logs.
 */
+(void)setLogLevel:(HZIMSDKLogLevel)desiredLogLevel;

+(void)setLocation:(CLLocation*)location;

@end
