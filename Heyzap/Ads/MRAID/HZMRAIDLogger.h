//
//  SKLogger.h
//  SourceKit
//
//  Created by Tom Poland on 9/24/13.
//  Copyright 2013 Nexage Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HZMRAIDLogLevelNone,
    HZMRAIDLogLevelError,
    HZMRAIDLogLevelWarning,
    HZMRAIDLogLevelInfo,
    HZMRAIDLogLevelDebug,
} HZMRAIDLogLevel;

// A simple logger enable you to see different levels of logging.
// Use logLevel as a filter to see the messages for the specific level.
//
@interface HZMRAIDLogger : NSObject

// Method to filter logging with the level passed as the paramter
+ (void)setLogLevel:(HZMRAIDLogLevel)logLevel;

+ (void)error:(NSString *)tag withMessage:(NSString *)message;
+ (void)warning:(NSString *)tag withMessage:(NSString *)message;
+ (void)info:(NSString *)tag withMessage:(NSString *)message;
+ (void)debug:(NSString *)tag withMessage:(NSString *)message;

@end
