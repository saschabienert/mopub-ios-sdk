//
//  HeyzapUDID.h
//  heyzapudid
//


#import <Foundation/Foundation.h>

//
// Usage:
//    #include "HeyzapUDID.h"
//    NSString* HeyzapUDID = [HeyzapUDID value];
//

#define kHeyzapUDIDErrorNone          0
#define kHeyzapUDIDErrorOptedOut      1
#define kHeyzapUDIDErrorCompromised   2

@interface HeyzapUDID : NSObject {
}
+ (NSString*) value;
+ (NSString*) valueWithError:(NSError**)error;

@end