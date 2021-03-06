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
    
    NSMutableString *mutableString = [NSMutableString stringWithString:url];
    
    hzReplaceSubstringWithString(mutableString, @"{MAC_ADDRESS_MD5}", @""); // Deprecated
    hzReplaceSubstringWithString(mutableString, @"{MAC_ADDRESS}", @""); // Deprecated
    hzReplaceSubstringWithString(mutableString, @"{IDFA}", [HZDevice HZadvertisingIdentifier]);
    hzReplaceSubstringWithString(mutableString, @"{IMPRESSION_ID}", impressionID);
    hzReplaceSubstringWithString(mutableString, @"{ODIN}", @""); // Deprecated
    hzReplaceSubstringWithString(mutableString, @"{UDID}", @""); // Deprecated
    hzReplaceSubstringWithString(mutableString, @"{OPEN_UDID}", @""); // Deprecated
    hzReplaceSubstringWithString(mutableString, @"{IDFV}", [HZDevice HZvendorDeviceIdentity]);
    
    return mutableString;
}

inline NSMutableString * hzReplaceSubstringWithString(NSMutableString *mutableString, NSString *subtring, NSString *replacement) {
    [mutableString replaceOccurrencesOfString:subtring withString:replacement options:NSLiteralSearch range:NSMakeRange(0, [mutableString length])];
    return mutableString;
}

@end
