//
//  SKLogger.m
//  MRAID
//
//  Created by Daniel Rhodes on 6/2/15.
//  Copyright (c) 2015 Nexage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZMRAIDLogger.h"

@implementation HZMRAIDLogger

+ (void)setLogLevel:(HZMRAIDLogLevel)logLevel {
    
}
+ (void)error:(NSString *)tag withMessage:(NSString *)message {
    NSLog(@"%@ %@", tag, message);
}
+ (void)warning:(NSString *)tag withMessage:(NSString *)message {
    NSLog(@"%@ %@", tag, message);
    
}

+ (void)info:(NSString *)tag withMessage:(NSString *)message {
    NSLog(@"%@ %@", tag, message);
    
}

+ (void)debug:(NSString *)tag withMessage:(NSString *)message {
    NSLog(@"%@ %@", tag, message);
    
}

@end