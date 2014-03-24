//
//  HZDevice.m
//  Heyzap
//
//  Created by Daniel Rhodes on 2/13/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZDevice.h"

#import "HZUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import <AdSupport/ASIdentifierManager.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <arpa/inet.h> // For AF_INET, etc.
#include <ifaddrs.h> // For getifaddrs()
#include <net/if.h> // For IFF_LOOPBACK

@implementation HZDevice

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

// http://stackoverflow.com/a/8036320/1176156
- (NSString *)HZmacaddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

#pragma mark - Internet Capability

#define HZConnectivityTypeWifi @"WiFi"
#define HZConnectivityTypeWWAN @"WWAN"

- (NSString *) connectivityTypeForRadioAccessString: (NSString *) str {
    if (str == nil) {
        return nil;
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyGPRS"]) {
        return  @"gprs";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyEdge"]) {
        return @"edge";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyWCDMA"]) {
        return @"cdma";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyHSDPA"]) {
        return @"hspda";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyHSUPA"]) {
        return @"hsupa";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyCDMA1x"]) {
        return @"cdma";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyCDMAEVDORev0"]) {
        return @"evdo";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyCDMAEVDORevA"]) {
        return @"evdo";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyCDMAEVDORevB"]) {
        return @"evdo_b";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyeHRPD"]) {
        return @"ehrpd";
    }
    
    if ([str isEqualToString: @"CTRadioAccessTechnologyLTE"]) {
        return @"lte";
    }
    
    return  nil;
}


- (NSString *)HZConnectivityType {
    
    CTTelephonyNetworkInfo *const telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSString *radio = ({
        NSString *radio = nil;
        if ([telephonyInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) { // iOS 7+
            radio = [self connectivityTypeForRadioAccessString: telephonyInfo.currentRadioAccessTechnology];
        }
        
        radio;
    });
    
    if (radio == nil) {
        struct ifaddrs *addresses;
        struct ifaddrs *cursor;
        NSString *type = nil;
        
        if (getifaddrs(&addresses) != 0) {
            type = @"";
        }
        
        cursor = addresses;
        while (cursor != NULL) {
            if (cursor->ifa_addr->sa_family == AF_INET && !(cursor->ifa_flags & IFF_LOOPBACK)) {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name hasPrefix:@"en"]) {
                    radio = @"wifi";
                } else if ([name hasPrefix:@"pdp_ip"] && !type) {
                    radio = @"wwan";
                }
            }
            cursor = cursor->ifa_next;
        }
    }
    
    return radio;
}

#pragma mark - Device Identifiers

- (NSString *) HZuniqueDeviceIdentifier{
    NSString *macaddress = [self HZmacaddress];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString *stringToHash = [NSString stringWithFormat:@"%@%@",macaddress,bundleIdentifier];
    NSString *uniqueIdentifier = [HZUtils base64EncodedStringFromString: stringToHash];
    
    return uniqueIdentifier;
}

- (NSString *) HZuniqueGlobalDeviceIdentifier{
    NSString *macaddress = [self HZmacaddress];
    NSString *uniqueIdentifier = [HZUtils base64EncodedStringFromString: macaddress];
    
    return uniqueIdentifier;
}

- (NSString *)HZmd5MacAddress {
    NSString *macaddress = [self HZmacaddress];
    const char *cStr = [macaddress UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest); // Casting to silence warning
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH *2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

// Warning: iOS will fail to give an advertising identifier when running tests from the command line. Stub this method as a workaround.
- (NSString *)HZadvertisingIdentifier {
    if(NSClassFromString(@"ASIdentifierManager")) {
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
    return @"";
}

- (NSString *)HZtrackingEnabled {
    if(NSClassFromString(@"ASIdentifierManager")) {
        return [[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled] ? @"1" : @"0";
    }
    return @"";
}

- (NSString *) HZvendorDeviceIdentity {
    if ([HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
        return  @"";
    } else {
        NSUUID *UUID = [[UIDevice currentDevice] identifierForVendor];
        if (UUID != nil) {
            return [UUID UUIDString];
        }
    }
    
    return @"";
}

- (NSDictionary *)HZIdentifierDictionary
{
    NSString *uniqueDeviceIdentifier = [self HZuniqueDeviceIdentifier] ?: @"";
    NSString *macAddress = [self HZmacaddress] ?: @"";
    NSString *uniqueGlobalDeviceIdentifier = [self HZuniqueGlobalDeviceIdentifier] ?: @"";
    NSString *md5MacAddress = [self HZmd5MacAddress] ?: @"";
    NSString *advertisingIdentifier = [self HZadvertisingIdentifier] ?: @"";
    NSString *connectivityType = [self HZConnectivityType] ?:@"";
    NSString *trackingEnabled = [self HZtrackingEnabled];
    NSString *vendorDeviceID = [self HZvendorDeviceIdentity];
    
    return @{
             @"vendor_device_id": vendorDeviceID,
             @"uniqueDeviceIdentifier": uniqueDeviceIdentifier,
             @"macAddress": macAddress,
             @"uniqueGlobalDeviceIdentifier":uniqueGlobalDeviceIdentifier,
             @"md5MacAddress":md5MacAddress,
             @"advertisingIdentifier":advertisingIdentifier,
             @"connection_type":connectivityType,
             @"tracking_enabled":trackingEnabled
             };
}

-(uint64_t)hzGetFreeDiskspace {
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    }
    
    return totalFreeSpace;
}

+ (BOOL) hzSystemVersionIsLessThan: (NSString *) version {
    return ([[[UIDevice currentDevice] systemVersion] compare: version options:NSNumericSearch] == NSOrderedAscending);
}

+ (HZDevice *)currentDevice {
    static HZDevice *currentDevice;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!currentDevice) {
            currentDevice = [[HZDevice alloc] init];
        }
    });
    return currentDevice;
}

@end
