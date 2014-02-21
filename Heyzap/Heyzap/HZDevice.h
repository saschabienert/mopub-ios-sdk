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
- (NSString *) HZOpenUDID;
- (BOOL) hzHasInternetConnection;
- (NSString *) HZConnectivityType;
- (NSString *) HZuniqueDeviceIdentifier;
- (NSString *) HZuniqueGlobalDeviceIdentifier;
- (NSString *) HZadvertisingIdentifier;
- (NSString *) HZtrackingEnabled;
- (NSString *) HZvendorDeviceIdentity;
- (NSString *) HZmd5MacAddress;
- (NSString *) HZmacaddress;
- (NSString *) HZODIN1;


+ (BOOL) hzSystemVersionIsLessThan: (NSString *) version;

@end
