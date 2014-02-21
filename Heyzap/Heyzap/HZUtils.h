//
//  HZUtils.h
//  Heyzap
//
//  Created by Daniel Rhodes on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HZUtils.h"

char *HZNewBase64Encode(
                        const void *buffer,
                        size_t length,
                        bool separateLines,
                        size_t *outputLength);

enum {
    Device_iPhoneStandardRes      = 1,    // iPhone 1,3,3GS Standard Resolution   (320x480px)
    Device_iPhoneHiRes            = 2,    // iPhone 4,4S High Resolution          (640x960px)
    Device_iPhoneTallerHiRes      = 3,    // iPhone 5 High Resolution             (640x1136px)
    Device_iPadStandardRes        = 4,    // iPad 1,2 Standard Resolution         (1024x768px)
    Device_iPadHiRes              = 5     // iPad 3 High Resolution               (2048x1536px)
}; typedef NSUInteger DeviceResolution;

@interface HZUtils : NSObject

+(NSString *)urlEncodeString: (NSString *) string usingEncoding:(NSStringEncoding)encoding;
+ (NSString *)base64EncodedStringFromString: (NSString *) string;
+ (NSString *) MD5FromString: (NSString *) string;
+ (BOOL) statusBarShowing;
+ (DeviceResolution) currentResolution;
+ (id) objectFromArchivedData: (NSData *) data;
+ (NSData *) dataFromObject: (id<NSCoding>) object;
+ (NSString *) deviceID;
+ (BOOL) canOpenHeyzap;
+ (void) openHeyzap;
+ (void) setAppID: (NSString *) appID;
+ (NSString *) appID;
+ (NSString *) bundleIdentifier;
+ (NSString *) pathWithFilename: (NSString *) filename;
+ (NSString *) cacheDirectoryPath;
+ (NSString *) cacheDirectoryWithFilename: (NSString *) filename;
+ (void) createCacheDirectory;
+ (UIImage *)heyzapBundleImageNamed:(NSString *)name;
+ (NSMutableDictionary *)hzQueryDictionaryFromURL: (NSURL *) url;
+ (NSMutableDictionary *)hzQueryStringToDictionary:(NSString *)string;
+ (UIWindow *)windowOrNil;
+ (CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation;
+ (CGSize) currentScreenSize;

@end
