//
//  NSArrayUtils.h
//  Heyzap
//
//  Created by Daniel Rhodes on 2/13/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZArrayUtils : NSObject
+ (NSArray *)map: (id (^)(id obj))block fromArray: (NSArray *) arr;
@end
