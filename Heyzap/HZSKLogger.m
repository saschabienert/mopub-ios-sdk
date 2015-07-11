//
//  SKLogger.m
//  SourceKit
//
//  Created by Tom Poland on 9/24/13.
//  Copyright 2013 Nexage Inc. All rights reserved.
//

#import "HZSKLogger.h"
#import "HZLog.h"

@implementation HZSKLogger

+ (void)error:(NSString *)tag withMessage:(NSString *)message
{
    HZELog(@"HZSKLogger %@: (E) %@", tag, message);
}

+ (void)warning:(NSString *)tag withMessage:(NSString *)message
{
    HZELog(@"HZSKLogger %@: (W) %@", tag, message);
}

+ (void)info:(NSString *)tag withMessage:(NSString *)message
{
    HZILog(@"HZSKLogger %@: (I) %@", tag, message);
}

+ (void)debug:(NSString *)tag withMessage:(NSString *)message
{
    HZDLog(@"HZSKLogger %@: (D) %@", tag, message);
}

@end
