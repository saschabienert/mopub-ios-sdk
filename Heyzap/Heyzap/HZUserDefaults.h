//
//  HZUserDefaults.h
//  Heyzap
//
//  Created by Daniel Rhodes on 11/2/12.
//
//

#import <Foundation/Foundation.h>

@interface HZUserDefaults : NSObject

+ (HZUserDefaults *)sharedDefaults;
- (void) setObject: (id<NSCoding>) obj forKey: (NSString *) key;
- (id) objectForKey: (NSString *) key;
- (id) objectForKey:(NSString *)key withDefault: (id) defaultObj;
- (void) removeObjectForKey: (NSString *) key;
- (void) setObject: (id<NSCoding>) obj inArrayForKey: (NSString *) key;

@end
