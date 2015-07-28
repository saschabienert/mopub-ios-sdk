//
//  HZCachingService.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/28/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZCachingService.h"
#import "HZUtils.h"

@implementation HZCachingService

- (void)cacheDictionary:(NSDictionary *)dictionary filename:(NSString *)filename {
    [dictionary writeToURL:[self cacheUrlForFilename:filename] atomically:YES];
}
- (NSDictionary *)dictionaryWithFilename:(NSString *)filename {
    return [NSDictionary dictionaryWithContentsOfURL:[self cacheUrlForFilename:filename]];
}

- (NSURL *)cacheUrlForFilename:(NSString *)filename {
    return [NSURL fileURLWithPath:[HZUtils cacheDirectoryWithFilename:filename] isDirectory:NO];
}

@end
