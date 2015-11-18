//
//  HZFetchOptions.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"

@interface HZFetchOptions : NSObject <NSCopying>

// Info passed to HeyzapMediation for a fetch
@property (nonatomic, strong, nullable) NSString *tag;
@property (nonatomic) HZAdType requestingAdType;
@property (nonatomic, nullable) NSDictionary *additionalParameters;
@property (nonatomic, nullable, copy) void (^completion)(BOOL result,  NSError * __nullable error );

@property (nonatomic, nullable) NSString *placementIDOverride;

@end
