//
//  HZCachingService.h
//  Heyzap
//
//  Created by Maximilian Tagher on 7/28/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HZCachingService : NSObject

- (void)cacheDictionary:(NSDictionary *)dictionary filename:(NSString *)filename;
- (NSDictionary *)dictionaryWithFilename:(NSString *)filename;

#pragma mark - Testing

- (NSURL *)cacheUrlForFilename:(NSString *)filename;

@end
