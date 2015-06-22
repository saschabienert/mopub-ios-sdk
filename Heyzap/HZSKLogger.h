//
//  SKLogger.h
//  SourceKit
//
//  Created by Tom Poland on 9/24/13.
//  Copyright 2013 Nexage Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

//typedef enum {
//    HZSourceKitLogLevelNone,
//    HZSourceKitLogLevelError,
//    HZSourceKitLogLevelWarning,
//    HZSourceKitLogLevelInfo,
//    HZSourceKitLogLevelDebug,
//} HZSourceKitLogLevel;

// A simple logger enable you to see different levels of logging.
// Use logLevel as a filter to see the messages for the specific level.
//
@interface HZSKLogger : NSObject

// Method to filter logging with the level passed as the paramter
//+ (void)setLogLevel:(HZSourceKitLogLevel)logLevel;

+ (void)error:(NSString *)tag withMessage:(NSString *)message;
+ (void)warning:(NSString *)tag withMessage:(NSString *)message;
+ (void)info:(NSString *)tag withMessage:(NSString *)message;
+ (void)debug:(NSString *)tag withMessage:(NSString *)message;

@end
