//
//  HZCachingService.h
//  Heyzap
//
//  Created by Maximilian Tagher on 7/28/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HZCachingService : NSObject

- (void)cacheRootObject:(id<NSCoding>)rootObject filename:(NSString *)filename;

- (id __nullable)rootObjectWithFilename:(NSString *)filename;

#pragma mark - Testing

- (NSURL *__nullable)cacheUrlForFilename:(NSString *)filename;

NS_ASSUME_NONNULL_END

@end
