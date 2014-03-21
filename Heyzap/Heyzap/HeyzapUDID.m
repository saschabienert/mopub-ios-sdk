//
//  HeyzapUDID.m
//  heyzapudid
//

#if __has_feature(objc_arc)
#error This file uses the classic non-ARC retain/release model; hints below...
// to selectively compile this file as non-ARC, do as follows:
// https://img.skitch.com/20120717-g3ag5h9a6ehkgpmpjiuen3qpwp.png
#endif

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#import "HeyzapUDID.h"
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access
#import <UIKit/UIPasteboard.h>
#import <UIKit/UIKit.h>

#define HeyzapUDIDLog(fmt, ...)
//#define HeyzapUDIDLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#define HeyzapUDIDLog(fmt, ...) NSLog((@"[Line %d] " fmt), __LINE__, ##__VA_ARGS__);

static NSString * kHeyzapUDIDSessionCache = nil;
//static NSString * const kHeyzapUDIDDescription = @"HZUDID_with_iOS6_Support";
static NSString * const kHeyzapUDIDKey = @"HZUDID";
static NSString * const kHeyzapUDIDSlotKey = @"HZUDID_slot";
static NSString * const kHeyzapUDIDAppUIDKey = @"HZUDID_appUID";
static NSString * const kHeyzapUDIDTSKey = @"HZUDID_createdTS";
static NSString * const kHeyzapUDIDDomain = @"com.heyzap";
static NSString * const kHeyzapUDIDSlotPBPrefix = @"com.heyzap.udid.slot.";
static int const kHeyzapUDIDRedundancySlots = 100;

@interface HeyzapUDID (Private)
+ (void) _setDict:(id)dict forPasteboard:(id)pboard;
+ (NSMutableDictionary*) _getDictFromPasteboard:(id)pboard;
+ (NSString*) _generateFreshHeyzapUDID;
@end

@implementation HeyzapUDID

// Archive a NSDictionary inside a pasteboard of a given type
// Convenience method to support iOS & Mac OS X
//
+ (void) _setDict:(id)dict forPasteboard:(id)pboard {
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:dict] forPasteboardType:kHeyzapUDIDDomain];
}

// Retrieve an NSDictionary from a pasteboard of a given type
// Convenience method to support iOS & Mac OS X
//
+ (NSMutableDictionary*) _getDictFromPasteboard:(id)pboard {
    id item = [pboard dataForPasteboardType:kHeyzapUDIDDomain];
    if (item) {
        @try{
            item = [NSKeyedUnarchiver unarchiveObjectWithData:item];
        } @catch(NSException* e) {
            item = nil;
        }
    }
    
    // return an instance of a MutableDictionary
    return [NSMutableDictionary dictionaryWithDictionary:(item == nil || [item isKindOfClass:[NSDictionary class]]) ? item : nil];
}

// Private method to create and return a new OpenUDID
// Theoretically, this function is called once ever per application when calling [OpenUDID value] for the first time.
// After that, the caching/pasteboard/redundancy mechanism inside [OpenUDID value] returns a persistent and cross application OpenUDID
//
+ (NSString*) _generateFreshHeyzapUDID {
    
    NSString* _heyzapUDID = nil;
    if (_heyzapUDID==nil) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef cfstring = CFUUIDCreateString(kCFAllocatorDefault, uuid);
        const char *cStr = CFStringGetCStringPtr(cfstring,CFStringGetFastestEncoding(cfstring));
        unsigned char result[16];
        CC_MD5( cStr, strlen(cStr), result );
        CFRelease(uuid);
        CFRelease(cfstring);
        
        _heyzapUDID = [NSString stringWithFormat:
                     @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%08x",
                     result[0], result[1], result[2], result[3],
                     result[4], result[5], result[6], result[7],
                     result[8], result[9], result[10], result[11],
                     result[12], result[13], result[14], result[15],
                     (NSUInteger)(arc4random() % NSUIntegerMax)];
    }
    
    // Call to other developers in the Open Source community:
    //
    // feel free to suggest better or alternative "UDID" generation code above.
    // NOTE that the goal is NOT to find a better hash method, but rather, find a decentralized (i.e. not web-based)
    // 160 bits / 20 bytes random string generator with the fewest possible collisions.
    //
    
    return _heyzapUDID;
}


// Main public method that returns the OpenUDID
// This method will generate and store the OpenUDID if it doesn't exist, typically the first time it is called
// It will return the null udid (forty zeros) if the user has somehow opted this app out (this is subject to 3rd party implementation)
// Otherwise, it will register the current app and return the OpenUDID
//
+ (NSString*) value {
    return [HeyzapUDID valueWithError:nil];
}

+ (NSString*) valueWithError:(NSError **)error {
    
    if (kHeyzapUDIDSessionCache!=nil) {
        if (error!=nil)
            *error = [NSError errorWithDomain:kHeyzapUDIDDomain
                                         code:kHeyzapUDIDErrorNone
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"OpenUDID in cache from first call",@"description", nil]];
        return kHeyzapUDIDSessionCache;
    }
    
  	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // The AppUID will uniquely identify this app within the pastebins
    //
    NSString * appUID = [defaults objectForKey:kHeyzapUDIDAppUIDKey];
    if(appUID == nil)
    {
        // generate a new uuid and store it in user defaults
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        appUID = (NSString *) CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        [appUID autorelease];
    }
    
    NSString* heyzapUDID = nil;
    NSString* myRedundancySlotPBid = nil;
    BOOL saveLocalDictToDefaults = NO;
    BOOL isCompromised = NO;
    
    // Do we have a local copy of the OpenUDID dictionary?
    // This local copy contains a copy of the openUDID, myRedundancySlotPBid (and unused in this block, the local bundleid, and the timestamp)
    //
    id localDict = [defaults objectForKey:kHeyzapUDIDKey];
    if ([localDict isKindOfClass:[NSDictionary class]]) {
        localDict = [NSMutableDictionary dictionaryWithDictionary:localDict]; // we might need to set/overwrite the redundancy slot
        heyzapUDID = [localDict objectForKey:kHeyzapUDIDKey];
        myRedundancySlotPBid = [localDict objectForKey:kHeyzapUDIDSlotKey];
    }
    
    // Here we go through a sequence of slots, each of which being a UIPasteboard created by each participating app
    // The idea behind this is to both multiple and redundant representations of OpenUDIDs, as well as serve as placeholder for potential opt-out
    //
    NSString* availableSlotPBid = nil;
    NSMutableDictionary* frequencyDict = [NSMutableDictionary dictionaryWithCapacity:kHeyzapUDIDRedundancySlots];
    for (int n=0; n<kHeyzapUDIDRedundancySlots; n++) {
        NSString* slotPBid = [NSString stringWithFormat:@"%@%d",kHeyzapUDIDSlotPBPrefix,n];
        UIPasteboard* slotPB = [UIPasteboard pasteboardWithName:slotPBid create:NO];
        if (slotPB==nil) {
            // assign availableSlotPBid to be the first one available
            if (availableSlotPBid==nil) availableSlotPBid = slotPBid;
        } else {
            NSDictionary* dict = [HeyzapUDID _getDictFromPasteboard:slotPB];
            NSString* oudid = [dict objectForKey:kHeyzapUDIDKey];
            if (oudid==nil) {
                // availableSlotPBid could inside a non null slot where no oudid can be found
                if (availableSlotPBid==nil) availableSlotPBid = slotPBid;
            } else {
                // increment the frequency of this oudid key
                int count = [[frequencyDict valueForKey:oudid] intValue];
                [frequencyDict setObject:[NSNumber numberWithInt:++count] forKey:oudid];
            }
            // if we have a match with the app unique id,
            // then let's look if the external UIPasteboard representation marks this app as OptedOut
            NSString* gid = [dict objectForKey:kHeyzapUDIDAppUIDKey];
            if (gid!=nil && [gid isEqualToString:appUID]) {
                myRedundancySlotPBid = slotPBid;
                // the local dictionary is prime on the opt-out subject, so ignore if already opted-out locally
            }
        }
    }
    
    // sort the Frequency dict with highest occurence count of the same OpenUDID (redundancy, failsafe)
    // highest is last in the list
    //
    NSArray* arrayOfUDIDs = [frequencyDict keysSortedByValueUsingSelector:@selector(compare:)];
    NSString* mostReliableHeyzapUDID = (arrayOfUDIDs!=nil && [arrayOfUDIDs count]>0)? [arrayOfUDIDs lastObject] : nil;
    
    // if openUDID was not retrieved from the local preferences, then let's try to get it from the frequency dictionary above
    //
    if (heyzapUDID==nil) {
        if (mostReliableHeyzapUDID==nil) {
            // this is the case where this app instance is likely to be the first one to use OpenUDID on this device
            // we create the OpenUDID, legacy or semi-random (i.e. most certainly unique)
            //
            heyzapUDID = [HeyzapUDID _generateFreshHeyzapUDID];
        } else {
            // or we leverage the OpenUDID shared by other apps that have already gone through the process
            //
            heyzapUDID = mostReliableHeyzapUDID;
        }
        // then we create a local representation
        //
        if (localDict==nil) {
            localDict = [NSMutableDictionary dictionaryWithCapacity:4];
            [localDict setObject:heyzapUDID forKey:kHeyzapUDIDKey];
            [localDict setObject:appUID forKey:kHeyzapUDIDAppUIDKey];
            [localDict setObject:[NSDate date] forKey:kHeyzapUDIDTSKey];
            saveLocalDictToDefaults = YES;
        }
    }
    else {
        // Sanity/tampering check
        //
        if (mostReliableHeyzapUDID!=nil && ![mostReliableHeyzapUDID isEqualToString:heyzapUDID])
            isCompromised = YES;
    }
    
    // Here we store in the available PB slot, if applicable
    //
    if (availableSlotPBid!=nil && (myRedundancySlotPBid==nil || [availableSlotPBid isEqualToString:myRedundancySlotPBid])) {
        UIPasteboard* slotPB = [UIPasteboard pasteboardWithName:availableSlotPBid create:YES];
        [slotPB setPersistent:YES];
        
        // save slotPBid to the defaults, and remember to save later
        //
        if (localDict) {
            [localDict setObject:availableSlotPBid forKey:kHeyzapUDIDSlotKey];
            saveLocalDictToDefaults = YES;
        }
        
        // Save the local dictionary to the corresponding UIPasteboard slot
        //
        if (heyzapUDID && localDict)
            [HeyzapUDID _setDict:localDict forPasteboard:slotPB];
    }
    
    // Save the dictionary locally if applicable
    //
    if (localDict && saveLocalDictToDefaults)
        [defaults setObject:localDict forKey:kHeyzapUDIDKey];
    
    // return the well earned openUDID!
    //
    if (error!=nil) {
        if (isCompromised)
            *error = [NSError errorWithDomain:kHeyzapUDIDDomain
                                         code:kHeyzapUDIDErrorCompromised
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Found a discrepancy between stored OpenUDID (reliable) and redundant copies; one of the apps on the device is most likely corrupting the OpenUDID protocol",@"description", nil]];
        else
            *error = [NSError errorWithDomain:kHeyzapUDIDDomain
                                         code:kHeyzapUDIDErrorNone
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"OpenUDID succesfully retrieved",@"description", nil]];
    }
    kHeyzapUDIDSessionCache = [heyzapUDID retain];
    return kHeyzapUDIDSessionCache;
}

@end