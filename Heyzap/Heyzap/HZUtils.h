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

@end
