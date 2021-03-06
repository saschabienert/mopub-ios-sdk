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

+ (id) objectFromArchivedData: (NSData *) data {
    if (!data) return nil;
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (NSData *) dataFromObject: (id<NSCoding>) object {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: object];
    return data;
}

+ (void) setPublisherID: (NSString *) publisherID {
    HZUtilsPublisherID = [publisherID copy];
}

+ (NSString *) publisherID {
    return HZUtilsPublisherID;
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
                                   withIntermediateDirectories:YES
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

// this method may not behave as intended if the input string contains backslashes. ex: it will treat `\r` as one character, not two. you can escape the backslash with another backslash to prevent this.
+ (NSString *)MD5ForString:(NSString *)string {
    if(!string) {
        return nil;
    }
    
    const char *cstr = [string UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (unsigned int)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}

// this method may not behave as intended if the input string contains backslashes. ex: it will treat `\r` as one character, not two. you can escape the backslash with another backslash to prevent this.
+ (NSString*) SHA1ForString:(NSString*)string
{
    // impl from: http://stackoverflow.com/a/7571583/2544629
    const char *cstr = [string UTF8String];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cstr, (unsigned int)strlen(cstr), digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

+ (BOOL) dateIsToday:(NSDate *)otherDate {
    NSDate *today = [HZUtils dateWithoutTimeFromDate:[NSDate date]];
    NSDate *otherDateToCompare = [HZUtils dateWithoutTimeFromDate:otherDate];
    
    return [today isEqualToDate:otherDateToCompare];
}

/**
 *  Returns a date object stripped of the current time, so dates can be compared for equality on a per-day granularity
 */
+ (NSDate *) dateWithoutTimeFromDate:(NSDate *)date {
    if(!date){
        return nil;
    }
    NSDate *outputDate = nil;
    if ([[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit startDate:&outputDate interval:NULL forDate:date]) {
        return outputDate;
    } else {
        return nil;
    }
}

NSArray *hzMap(NSArray *array, id (^block)(id object)) {
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (id obj in array) {
        id retVal = block(obj);
        if (retVal) [newArray addObject:retVal];
    }
    return newArray;
}
NSArray *hzFilter(NSArray *array, BOOL(^block)(id object)) {
    NSIndexSet *idxSet = [array indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];
    return [array objectsAtIndexes:idxSet];
}
id hzFirstObjectPassingTest(NSArray *array, BOOL(^test)(id object, NSUInteger index)) {
    __block id passingObj = nil;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (test(obj, idx)) {
            *stop = YES;
            passingObj = obj;
        }
    }];
    return passingObj;
}

NSOrderedSet *hzMapOrderedSet(NSOrderedSet *set, id (^block)(id object)) {
    NSMutableOrderedSet *newSet = [[NSMutableOrderedSet alloc] initWithCapacity:set.count];
    for (id obj in set) {
        id retVal = block(obj);
        if (retVal) [newSet addObject:retVal];
    }
    return newSet;
}
NSOrderedSet *hzFilterOrderedSet(NSOrderedSet *set, BOOL(^block)(id object)) {
    NSIndexSet *idxSet = [set indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];
    
    return [NSOrderedSet orderedSetWithArray:[set objectsAtIndexes:idxSet]];
}
id hzFirstObjectPassingTestOrderedSet(NSOrderedSet *set, BOOL(^test)(id object, NSUInteger index)) {
    __block id passingObj = nil;
    [set enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (test(obj, idx)) {
            *stop = YES;
            passingObj = obj;
        }
    }];
    return passingObj;
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
