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

#pragma mark - NSCoding

- (void)cacheRootObject:(id<NSCoding>)rootObject filename:(NSString *)filename {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
    [data writeToURL:[self cacheUrlForFilename:filename] atomically:YES];
}

- (id)rootObjectWithFilename:(NSString *)filename {
    NSData *data = [NSData dataWithContentsOfURL:[self cacheUrlForFilename:filename]];
    return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

- (NSURL *)cacheUrlForFilename:(NSString *)filename {
    return [NSURL fileURLWithPath:[HZUtils cacheDirectoryWithFilename:filename] isDirectory:NO];
}

@end
