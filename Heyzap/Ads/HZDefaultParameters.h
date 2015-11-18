//
//  HZDefaultParameters.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HZDefaultParameters : NSObject

extern NSString * const kHZEnvironmentParamsKey;

+ (NSMutableDictionary *)baseDefaultParams;

+ (NSMutableDictionary *)mediationDefaultParams;

@end

NS_ASSUME_NONNULL_END