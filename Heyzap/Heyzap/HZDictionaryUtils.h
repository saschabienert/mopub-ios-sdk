//
//  NSDictionary+ClassChecking.h
//  Heyzap
//
//  Created by Daniel Rhodes on 10/29/12.
//
//

#import <Foundation/Foundation.h>

@interface HZDictionaryUtils : NSObject
+ (id) objectForKey:(id)key ofClass:(Class)class dict: (NSDictionary *) dict;
+ (id) objectForKey:(id)key ofClass:(Class)class default:(id)_default dict: (NSDictionary *) dict;
+ (NSString*) hzUrlEncodedStringWithDict: (NSDictionary *) dic;

+ (id)objectForKey:(id)key ofClass:(Class)class dict:(NSDictionary *)dict error:(NSError **)error;

extern NSString * const kHZMissingPropertyKey;

@end
