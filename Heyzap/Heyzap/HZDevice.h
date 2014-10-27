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