//
//  SKLogger.h
//  SourceKit
//
//  Created by Tom Poland on 9/24/13.
//  Copyright 2013 Nexage Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZSKLogger : NSObject

+ (void)error:(NSString *)tag withMessage:(NSString *)message;
+ (void)warning:(NSString *)tag withMessage:(NSString *)message;
+ (void)info:(NSString *)tag withMessage:(NSString *)message;
+ (void)debug:(NSString *)tag withMessage:(NSString *)message;

@end
