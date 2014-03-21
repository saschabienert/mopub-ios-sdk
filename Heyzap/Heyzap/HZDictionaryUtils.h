//
//  NSDictionary+ClassChecking.h
//  Heyzap
//
//  Created by Daniel Rhodes on 10/29/12.
//
//

#import <Foundation/Foundation.h>

@interface HZDictionaryUtils : NSObject
+ (id) hzObjectForKey:(id)key ofClass:(Class)class withDict: (NSDictionary *) dict;
+ (id) hzObjectForKey:(id)key ofClass:(Class)class default:(id)_default withDict: (NSDictionary *) dict;
+ (NSString*) hzUrlEncodedStringWithDict: (NSDictionary *) dic;

@end
