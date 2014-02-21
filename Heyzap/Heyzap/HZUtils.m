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
#import "HeyzapUDID.h"


static NSString *HZUtilsAppID;
static NSString *HZUtilsDeviceID;

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
    
	size_t outputLength;
	char *outputBuffer =
    HZNewBase64Encode([data bytes], [data length], true, &outputLength);
	
	NSString *result =
    [[NSString alloc]
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

+ (NSString *) MD5FromString: (NSString *) string {
    // Create pointer to the string as UTF8
    const char *ptr = [string UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+ (BOOL) statusBarShowing {
    if ([[UIApplication sharedApplication] statusBarFrame].size.height > 0.0) {
        return YES;
    }
    
    return NO;
}

+ (DeviceResolution) currentResolution {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        if ([[UIScreen mainScreen] respondsToSelector: @selector(scale)]) {
            CGSize result = [[UIScreen mainScreen] bounds].size;
            result = CGSizeMake(result.width * [UIScreen mainScreen].scale, result.height * [UIScreen mainScreen].scale);
            if (result.height <= 480.0f)
                return Device_iPhoneStandardRes;
            return (result.height > 960 ? Device_iPhoneTallerHiRes : Device_iPhoneHiRes);
        } else
            return Device_iPhoneStandardRes;
    } else
        return (([[UIScreen mainScreen] respondsToSelector: @selector(scale)]) ? Device_iPadHiRes : Device_iPadStandardRes);
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
    NSString *deviceIdentifier;
    if (HZUtilsDeviceID != nil) {
        deviceIdentifier = HZUtilsDeviceID;
    } else if ([HZDevice hzSystemVersionIsLessThan: @"7.0"]) {
        deviceIdentifier = [[HZDevice currentDevice] HZuniqueGlobalDeviceIdentifier];
        HZUtilsDeviceID = [deviceIdentifier copy];
        NSString *filename = [HZUtils pathWithFilename: @"device.id"];
        [NSKeyedArchiver archiveRootObject: deviceIdentifier toFile: filename];
    } else {
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath: [HZUtils pathWithFilename: @"device.id"]];
        deviceIdentifier = fileExists ? (NSString *)[NSKeyedUnarchiver unarchiveObjectWithFile: [HZUtils pathWithFilename: @"device.id"]] : [HeyzapUDID value];
        HZUtilsDeviceID = [deviceIdentifier copy];
    }
    
    return deviceIdentifier;
}

+ (NSString *) pathWithFilename: (NSString *) filenameShort {
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *filename = [folders count] == 0 ? NSTemporaryDirectory() : [folders objectAtIndex:0];
    filename = [filename stringByAppendingPathComponent:[NSString stringWithFormat: @"Caches/%@.heyzap", filenameShort]];
    return filename;
}

+ (BOOL) canOpenHeyzap {
    return [[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString: @"heyzap://checkin"]];
}

+ (void) openHeyzap {
    if ([HZUtils canOpenHeyzap]) {
        NSURL *url = [NSURL URLWithString: @"heyzap://"];
        [[UIApplication sharedApplication] openURL: url];
    } else {
        
    }
}

+ (void) setAppID: (NSString *) appID {
    HZUtilsAppID = appID;
}

+ (NSString *) appID {
    return HZUtilsAppID;
}

+ (NSString *) bundleIdentifier {
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString *) cacheDirectoryPath {
    NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath    = [[pathList objectAtIndex: 0] stringByAppendingPathComponent: @"com.heyzap.sdk.ads"];
    return cachePath;
}

+ (NSString *) cacheDirectoryWithFilename: (NSString *) filename {
    return [[self cacheDirectoryPath] stringByAppendingPathComponent: filename];
}

+ (void) createCacheDirectory {
    NSString *cachePath = [self cacheDirectoryPath];
    NSError *error;
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                         error:&error])
    {}
}

+ (UIImage *)heyzapBundleImageNamed:(NSString *)name {
    return [UIImage imageNamed:[@"Heyzap.bundle/" stringByAppendingString:name]];
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

+ (UIWindow *) windowOrNil {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow) {
        return keyWindow;
    } else {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        if ([windows count] >= 1) {
            return [windows objectAtIndex:0];
        } else {
            return nil;
        }
    }
}

+(CGSize) currentScreenSize {
    return [HZUtils sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    if (application.statusBarHidden == NO)
    {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

@end
