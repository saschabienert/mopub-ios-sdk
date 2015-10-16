//
//  NSString+Tests.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "NSString+Tests.h"

@implementation NSString (Tests)

- (BOOL)hzContainsString:(NSString *)string
{
    NSParameterAssert(string);
    return [self rangeOfString:string].location != NSNotFound;
}

@end
