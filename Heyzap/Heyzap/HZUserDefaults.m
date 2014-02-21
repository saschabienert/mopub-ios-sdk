//
//  HZUserDefaults.m
//  Heyzap
//
//  Created by Daniel Rhodes on 11/2/12.
//
//

#import "HZUserDefaults.h"
#import "HZUtils.h"

NSString * const kHeyzapBaseKey = @"com.heyzap.sdk.%@";

@interface HZUserDefaults()
+ (NSString *) keyWithShortKey: (NSString *) key;
@end

@implementation HZUserDefaults

+ (HZUserDefaults *)sharedDefaults {
    static HZUserDefaults *_sharedDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDefaults = [[HZUserDefaults alloc] init];
    });
    
    return _sharedDefaults;
}

- (void) setObject: (id<NSCoding>) obj forKey: (NSString *) key {
    NSData *data = [HZUtils dataFromObject: obj];
    [[NSUserDefaults standardUserDefaults] setObject: data forKey: [HZUserDefaults keyWithShortKey: key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) setObject: (id<NSCoding>) obj inArrayForKey: (NSString *) key {
    NSMutableArray *arr;
    NSData *data = [HZUtils dataFromObject: obj];
    arr = [self objectForKey: key];
    if (!arr) {
        arr = [[NSMutableArray alloc] initWithCapacity: 0];
    }
    
    [arr addObject: data];
}

- (id) objectForKey: (NSString *) key {
    NSData *obj = [[NSUserDefaults standardUserDefaults] objectForKey: [HZUserDefaults keyWithShortKey: key]];
    if (!obj) return nil;
    
    id returnObj = [HZUtils objectFromArchivedData: obj];
    return returnObj;
}

- (id) objectForKey:(NSString *)key withDefault: (id) defaultObj {
    id anObj = [self objectForKey: key];
    if (!anObj) return defaultObj;
    return anObj;
}

- (void) removeObjectForKey: (NSString *) key {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: [HZUserDefaults keyWithShortKey: key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *) keyWithShortKey: (NSString *) key {
    return [NSString stringWithFormat: kHeyzapBaseKey, key];
}

@end
