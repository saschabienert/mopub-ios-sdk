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

@interface HZUtils : NSObject

+ (NSString *)urlEncodeString: (NSString *) string usingEncoding:(NSStringEncoding)encoding;
+ (NSString *)base64EncodedStringFromString: (NSString *) string;
+ (id) objectFromArchivedData: (NSData *) data;
+ (NSData *) dataFromObject: (id<NSCoding>) object;
+ (NSString *) deviceID;
+ (NSString *) pathWithFilename: (NSString *) filename;
+ (NSString *) cacheDirectoryPath;
+ (NSString *) cacheDirectoryWithFilename: (NSString *) filename;
+ (void) createCacheDirectory;
+ (NSMutableDictionary *)hzQueryDictionaryFromURL: (NSURL *) url;
+ (NSMutableDictionary *)hzQueryStringToDictionary:(NSString *)string;
+ (void) setPublisherID: (NSString *) publisherID;
+ (NSString *) publisherID;

NSArray *hzMap(NSArray *array, id (^block)(id object));

BOOL hziOS8Plus(void);

/**
 *  Looks up a string constant (e.g. `extern NSString *const kFoo;`) at runtime. This is useful for loading constant values for 3rd party SDKs that we don't have at compile time.
 *
 *  @param constantName The name of the constant, e.g. `VungleSDKVersion`.
 *
 *  @return The value of the string constant, if found, otherwise `nil`.
 */
NSString *hzLookupStringConstant(NSString *constantName);

@end
