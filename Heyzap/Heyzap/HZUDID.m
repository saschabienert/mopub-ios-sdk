//
//  OpenUDID.m
//  openudid
//
//  initiated by Yann Lechelle (cofounder Appsfire) on 8/28/11.
//  Copyright 2011 OpenUDID.org
//
//  This is actually based on a fork https://github.com/akrapacs/OpenUDID/blob/cfuuid/OpenUDID.m
//  but we have actually modified it ourselves (MASSIVELY).
//
//  iOS / MacOS code: https://github.com/ylechelle/OpenUDID
//  Android code: https://github.com/vieux/OpenUDID
//
//  Contributors:
//      https://github.com/ylechelle (initiator & iOS code)
//      https://github.com/samrobbins (Mac OS port)
//      https://github.com/vieux (Android version)

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

#import "HZUDID.h"
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access
#import <UIKit/UIPasteboard.h>
#import <UIKit/UIKit.h>


static NSString * kOpenUDIDSessionCache = nil;
static NSString * const kHeyzapUDIDKey = @"HZID";
static NSString * const kHeyzapPasteboardName = @"HZPaste";

@interface HZUDID (Private)
+ (NSString*) _getOpenUDID;
@end

@implementation HZUDID

+ (NSString*) _getOpenUDID {
    // UUIDs (Universally Unique Identifiers), also known as GUIDs (Globally Unique Identifiers) or IIDs 
    // (Interface Identifiers), are 128-bit values guaranteed to be unique. A UUID is made unique over 
    // both space and time by combining a value unique to the computer on which it was generated—usually the
    // Ethernet hardware address—and a value representing the number of 100-nanosecond intervals since 
    // October 15, 1582 at 00:00:00.
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef cfstring = CFUUIDCreateString(NULL, uuid);
    NSString *string = (NSString *)cfstring;
    NSString* _openUDID = [string autorelease];
    CFRelease(uuid);

    return _openUDID;
}

+ (NSString*) value {
    if (kOpenUDIDSessionCache!=nil) {
        return kOpenUDIDSessionCache;
    }

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* openUDID = nil;
    
    // Do we have a local copy of the OpenUDID dictionary?
    // This local copy contains a copy of the openUDID, myRedundancySlotPBid (and unused in this block, the local bundleid, and the timestamp)
    id localUDID = [defaults objectForKey:kHeyzapUDIDKey];
    if ([localUDID isKindOfClass:[NSString class]]) {
        openUDID = localUDID;
    }

    if(!openUDID) {
        UIPasteboard* pasteboard = [UIPasteboard pasteboardWithName:kHeyzapPasteboardName create:NO];
        if (pasteboard!=nil) {
            openUDID = pasteboard.string;
        }
    }
        
    if (!openUDID) {        
        openUDID = [HZUDID _getOpenUDID];
        
        [defaults setObject:openUDID forKey:kHeyzapUDIDKey];
        [defaults synchronize];
        UIPasteboard* pasteboard = [UIPasteboard pasteboardWithName:kHeyzapPasteboardName create:YES];
        [pasteboard setPersistent:YES];
        pasteboard.string = openUDID;
    }

    kOpenUDIDSessionCache = [openUDID retain];
    return kOpenUDIDSessionCache;
}

@end
