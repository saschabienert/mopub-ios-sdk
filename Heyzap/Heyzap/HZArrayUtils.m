//
//  NSArrayUtils.m
//  Heyzap
//
//  Created by Daniel Rhodes on 2/13/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZArrayUtils.h"

@implementation HZArrayUtils

+ (NSArray *)map: (id (^)(id obj))block fromArray: (NSArray *) arr {
    NSMutableArray *new = [NSMutableArray array];
    for(id obj in arr) {
        id newObj = block(obj);
        [new addObject: newObj ? newObj : [NSNull null]];
    }
    return new;
}

@end
