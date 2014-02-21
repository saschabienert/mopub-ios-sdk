//
//  NSDictionary+ClassChecking.m
//  Heyzap
//
//  Created by Daniel Rhodes on 10/29/12.
//
//

#import "HZDictionaryUtils.h"

@implementation HZDictionaryUtils

+ (id) hzObjectForKey:(id)key ofClass:(Class)class withDict: (NSDictionary *) dict {
    return [self hzObjectForKey:key ofClass:class default:nil withDict: dict];
}

+ (id) hzObjectForKey:(id)key ofClass:(Class)class default:(id)_default withDict: (NSDictionary *) dict {
    id value = [dict objectForKey:key];
    if ([value isKindOfClass:class])
        return value;
    return _default;
}

static NSString *hzToString(id object) {
    return [NSString stringWithFormat: @"%@", object];
}

// helper function: get the url encoded string form of any object
static NSString *hzUrlEncode(id object) {
    NSString *string = hzToString(object);
    return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

+ (NSString*) hzUrlEncodedStringWithDict: (NSDictionary *) dict {
    NSMutableArray *parts = [NSMutableArray array];
    for (id key in dict) {
        id value = [dict objectForKey: key];
        NSString *part = [NSString stringWithFormat: @"%@=%@", hzUrlEncode(key), hzUrlEncode(value)];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

@end