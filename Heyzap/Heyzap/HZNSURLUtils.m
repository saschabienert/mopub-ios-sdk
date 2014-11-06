//
//  HZNSURLUtils.m
//  Heyzap
//
//  Created by Maximilian Tagher on 11/5/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZNSURLUtils.h"
#import "HZDevice.h"

@implementation HZNSURLUtils

+ (NSString *)substituteGetParams:(NSString *)url impressionID:(NSString *)impressionID {
    NSString *result = [url stringByReplacingOccurrencesOfString:@"{MAC_ADDRESS_MD5}" withString:[[HZDevice currentDevice] HZmd5MacAddress]];
    result = [result stringByReplacingOccurrencesOfString:@"{MAC_ADDRESS}" withString:[[HZDevice currentDevice] HZmacaddress]];
    result = [result stringByReplacingOccurrencesOfString:@"{IDFA}" withString:[[HZDevice currentDevice] HZadvertisingIdentifier]];
    result = [result stringByReplacingOccurrencesOfString:@"{IMPRESSION_ID}" withString:impressionID];
    result = [result stringByReplacingOccurrencesOfString:@"{ODIN}" withString:@""]; // Deprecated
    result = [result stringByReplacingOccurrencesOfString: @"{UDID}" withString: @""]; // Deprecated
    result = [result stringByReplacingOccurrencesOfString: @"{OPEN_UDID}" withString: @""]; // Deprecated
    result = [result stringByReplacingOccurrencesOfString: @"{IDFV}" withString: [[HZDevice currentDevice] HZvendorDeviceIdentity]];
    
    return result;
}

@end
