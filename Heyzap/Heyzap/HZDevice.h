//
//  HZDevice.h
//  Heyzap
//
//  Created by Daniel Rhodes on 2/13/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZDevice : NSObject

+ (HZDevice *) currentDevice;

// This method executes once and returns the same value going forward (so as not to constantly be going to disk).
-(uint64_t) hzGetFreeDiskspace;
- (NSDictionary *) HZIdentifierDictionary;
- (NSString *) HZConnectivityType;
- (NSString *) HZuniqueGlobalDeviceIdentifier;
- (NSString *) HZadvertisingIdentifier;
- (NSString *) HZvendorDeviceIdentity;
- (NSString *) HZmd5MacAddress;
- (NSString *) HZmacaddress;


+ (BOOL) hzSystemVersionIsLessThan: (NSString *) version;

@end
