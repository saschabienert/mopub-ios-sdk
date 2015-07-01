//
//  HZUtils.m
//  Heyzap
//
//  Created by Daniel Rhodes on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HZUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import "HZDevice.h"


static NSString *HZUtilsDeviceID;
static NSString *HZUtilsPublisherID;

static unsigned char HZbase64EncodeLookup[65] =
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

//
// Fundamental sizes of the binary and base64 encode/decode units in bytes
//
#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4

char *HZNewBase64Encode(
                      const void *buffer,
                      size_t length,
                      bool separateLines,
                      size_t *outputLength)
{
	const unsigned char *inputBuffer = (const unsigned char *)buffer;
	
#define MAX_NUM_PADDING_CHARS 2
#define OUTPUT_LINE_LENGTH 64
#define INPUT_LINE_LENGTH ((OUTPUT_LINE_LENGTH / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE)
#define CR_LF_SIZE 2
	
	//
	// Byte accurate calculation of final buffer size
	//
	size_t outputBufferSize =
    ((length / BINARY_UNIT_SIZE)
     + ((length % BINARY_UNIT_SIZE) ? 1 : 0))
    * BASE64_UNIT_SIZE;
	if (separateLines)
	{
		outputBufferSize +=
        (outputBufferSize / OUTPUT_LINE_LENGTH) * CR_LF_SIZE;
	}
	
	//
	// Include space for a terminating zero
	//
	outputBufferSize += 1;
    
	//
	// Allocate the output buffer
	//
	char *outputBuffer = (char *)malloc(outputBufferSize);
	if (!outputBuffer)
	{
		return NULL;
	}
    
	size_t i = 0;
	size_t j = 0;
	const size_t lineLength = separateLines ? INPUT_LINE_LENGTH : length;
	size_t lineEnd = lineLength;
	
	while (true)
	{
		if (lineEnd > length)
		{
			lineEnd = length;
		}
        
		for (; i + BINARY_UNIT_SIZE - 1 < lineEnd; i += BINARY_UNIT_SIZE)
		{
			//
			// Inner loop: turn 48 bytes into 64 base64 characters
			//
			outputBuffer[j++] = HZbase64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
			outputBuffer[j++] = HZbase64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                                   | ((inputBuffer[i + 1] & 0xF0) >> 4)];
			outputBuffer[j++] = HZbase64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2)
                                                   | ((inputBuffer[i + 2] & 0xC0) >> 6)];
			outputBuffer[j++] = HZbase64EncodeLookup[inputBuffer[i + 2] & 0x3F];
		}
		
		if (lineEnd == length)
		{
			break;
		}
		
		//
		// Add the newline
		//
		outputBuffer[j++] = '\r';
		outputBuffer[j++] = '\n';
		lineEnd += lineLength;
	}
	
	if (i + 1 < length)
	{
		//
		// Handle the single '=' case
		//
		outputBuffer[j++] = HZbase64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = HZbase64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                               | ((inputBuffer[i + 1] & 0xF0) >> 4)];
		outputBuffer[j++] = HZbase64EncodeLookup[(inputBuffer[i + 1] & 0x0F) << 2];
		outputBuffer[j++] =	'=';
	}
	else if (i < length)
	{
		//
		// Handle the double '=' case
		//
		outputBuffer[j++] = HZbase64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = HZbase64EncodeLookup[(inputBuffer[i] & 0x03) << 4];
		outputBuffer[j++] = '=';
		outputBuffer[j++] = '=';
	}
	outputBuffer[j] = 0;
	
	//
	// Set the output length and return the buffer
	//
	if (outputLength)
	{
		*outputLength = j;
	}
	return outputBuffer;
}

@implementation HZUtils

+ (NSString *)base64EncodedStringFromString: (NSString *) string {
    
    NSData *data = [string dataUsingEncoding: NSUTF8StringEncoding];
    
	size_t outputLength = 0;
	char *outputBuffer =
    HZNewBase64Encode([data bytes], [data length], true, &outputLength);
	
    NSString *result = outputLength == 0 ? nil : [[NSString alloc]
                                                  initWithBytes:outputBuffer
                                                         length:outputLength
                                                       encoding:NSASCIIStringEncoding];
	free(outputBuffer);
	return result;
}

+(NSString *)urlEncodeString: (NSString *) string usingEncoding:(NSStringEncoding)encoding {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef) string,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(encoding)));
    
    return encodedString;
}

+ (id) objectFromArchivedData: (NSData *) data {
    if (!data) return nil;
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (NSData *) dataFromObject: (id<NSCoding>) object {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: object];
    return data;
}

+ (NSString *) deviceID {
    NSString *advertisingIdentifier = [[HZDevice currentDevice] HZadvertisingIdentifier];
    if ([advertisingIdentifier isEqualToString:@""]) {
        return [[HZDevice currentDevice] HZuniqueGlobalDeviceIdentifier];
    } else {
        return advertisingIdentifier;
    }
}

+ (void) setPublisherID: (NSString *) publisherID {
    HZUtilsPublisherID = [publisherID copy];
}

+ (NSString *) publisherID {
    return HZUtilsPublisherID;
}

+ (NSString *) pathWithFilename: (NSString *) filenameShort {
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *filename = [folders count] == 0 ? NSTemporaryDirectory() : [folders objectAtIndex:0];
    filename = [filename stringByAppendingPathComponent:[NSString stringWithFormat: @"Caches/%@.heyzap", filenameShort]];
    return filename;
}

+ (NSString *) cacheDirectoryPath {
    static NSString *cachePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [[pathList objectAtIndex: 0] stringByAppendingPathComponent: @"com.heyzap.sdk.ads"];
    });
    return cachePath;
}

+ (NSString *) cacheDirectoryWithFilename: (NSString *) filename {
    return [[self cacheDirectoryPath] stringByAppendingPathComponent: filename];
}

+ (void) createCacheDirectory {
    NSString *cachePath = [self cacheDirectoryPath];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                    error:nil];
}

+ (NSString *)hzDecode:(NSString *)s {
	if (!s) return nil;
	return CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL, (__bridge CFStringRef)s, CFSTR("")));
}

+ (NSMutableDictionary *)hzQueryStringToDictionary:(NSString *)string {
	NSArray *queryItemStrings = [string componentsSeparatedByString:@"&"];
    
	NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionaryWithCapacity:[queryItemStrings count]];
	for(NSString *queryItemString in queryItemStrings) {
		NSRange range = [queryItemString rangeOfString:@"="];
		if (range.location != NSNotFound) {
			NSString *key = [HZUtils hzDecode:[queryItemString substringToIndex:range.location]];
			NSString *value = [HZUtils hzDecode:[queryItemString substringFromIndex:range.location + 1]];
			[queryDictionary setObject:value forKey:key];
		}
	}
	return queryDictionary;
}

+ (NSMutableDictionary *)hzQueryDictionaryFromURL: (NSURL *) url {
	return [HZUtils hzQueryStringToDictionary:[url query]];
}

NSString *const kNoInternet = @"no_internet";

+ (NSString *)internetStatus {
    return [[HZDevice currentDevice] HZConnectivityType] ?: kNoInternet;
}

NSArray *hzMap(NSArray *array, id (^block)(id object)) {
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (id obj in array) {
        [newArray addObject:block(obj)];
    }
    return newArray;
}
NSArray *hzFilter(NSArray *array, BOOL(^block)(id object)) {
    NSIndexSet *idxSet = [array indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];
    return [array objectsAtIndexes:idxSet];
}

NSOrderedSet *hzFilterOrderedSet(NSOrderedSet *set, BOOL(^block)(id object)) {
    NSIndexSet *idxSet = [set indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];
    
    return [NSOrderedSet orderedSetWithArray:[set objectsAtIndexes:idxSet]];
}

BOOL hziOS8Plus(void) {
    static BOOL eightPlus;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // (All UIDevice access seems to take 1ms)
        eightPlus = [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0;
    });
    return eightPlus;
}

NSString *hzLookupStringConstant(NSString *constantName) {
    void ** dataPtr = CFBundleGetDataPointerForName(CFBundleGetMainBundle(), (__bridge CFStringRef)constantName);
    return (__bridge NSString *)(dataPtr ? *dataPtr : nil);
}

int64_t millisecondsSinceCFTimeInterval(CFTimeInterval startTime) {
    CFTimeInterval const currentTime = CACurrentMediaTime();
    return lround((currentTime - startTime) * 1000);
}


@end
