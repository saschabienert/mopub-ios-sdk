//
//  SKLogger.m
//  SourceKit
//
//  Created by Tom Poland on 9/24/13.
//  Copyright 2013 Nexage Inc. All rights reserved.
//

#import "HZSKLogger.h"
#import "HZLog.h"

// Default setting is SourceKitLogLevelNone.
//static HZSourceKitLogLevel logLevel;

@implementation HZSKLogger

//+ (void)setLogLevel:(HZSourceKitLogLevel)level
//{
//    NSArray *levelNames = @[
//                            @"none",
//                            @"error",
//                            @"warning",
//                            @"info",
//                            @"debug",
//                            ];
//    
//    NSString *levelName = levelNames[level];
//    NSLog(@"SourceKit Logger: log level set to %@", levelName);
//    logLevel = level;
//}

+ (void)error:(NSString *)tag withMessage:(NSString *)message
{
    //if (logLevel >= HZSourceKitLogLevelError) {
        HZELog(@"HZSKLogger %@: (E) %@", tag, message);
    //}
}

+ (void)warning:(NSString *)tag withMessage:(NSString *)message
{
    //if (logLevel >= HZSourceKitLogLevelWarning) {
        HZELog(@"HZSKLogger %@: (W) %@", tag, message);
    //}
}

+ (void)info:(NSString *)tag withMessage:(NSString *)message
{
    //if (logLevel >= HZSourceKitLogLevelInfo) {
        HZILog(@"HZSKLogger %@: (I) %@", tag, message);
    //}
}

+ (void)debug:(NSString *)tag withMessage:(NSString *)message
{
    //if (logLevel >= HZSourceKitLogLevelDebug) {
        HZDLog(@"HZSKLogger %@: (D) %@", tag, message);
    //}
}

@end
