//
//  HZDevice.h
//  Heyzap
//
//  Created by Daniel Rhodes on 2/13/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZOpenRTBConnectionType.h"

@interface HZDevice : NSObject

+ (HZDevice *) currentDevice;

// This method executes once and returns the same value going forward (so as not to constantly be going to disk).
+ (uint64_t) hzGetFreeDiskspace;
+ (NSDictionary *) HZIdentifierDictionary;
- (NSString *) HZConnectivityType;
+ (NSString *) HZadvertisingIdentifier;
+ (NSString *) HZvendorDeviceIdentity;
+ (NSString *) HZCarrierName;

- (HZOpenRTBConnectionType) getHZOpenRTBConnectionType;

+ (BOOL) hzSystemVersionIsLessThan: (NSString *) version;
+ (BOOL) hzSystemVersionIsGreaterOrEqualTo:(NSString *)version;
+ (NSString *) systemVersion;
+ (BOOL)isIpad;
+ (BOOL)isPhone;

+ (BOOL)isHeyzapTestApp;

+ (BOOL)canCheckURLSchemes;

#pragma mark - Overriding the bundle ID

+ (void)setBundleIdentifier:(NSString *)bundleIdentifier;
+ (NSString *)bundleIdentifier;

@end
