//
//  HZVASTVideoCache.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/24/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZVASTVideoCache.h"
#import "HZAFHTTPRequestOperation.h"
#import "HZDownloadHelper.h"
#import "HZUtils.h"

@interface HZVASTVideoCache()
@property (nonatomic) HZAFHTTPRequestOperation *downloadOperation;
@property (nonatomic) NSString *fileExtension;
@property (nonatomic) BOOL fileCached;
@property (nonatomic) NSURL * sourceURL;
@end

@implementation HZVASTVideoCache

- (void) startCaching:(NSURL *)sourceURL withCompletion:(void (^)(BOOL))completion{
    self.sourceURL = sourceURL;
    self.fileExtension = [sourceURL pathExtension];
    __weak HZVASTVideoCache *weakSelf = self;
    self.downloadOperation = [HZDownloadHelper downloadURL: self.sourceURL
                                                toFilePath: [self filePathForCachedVideo]
                                                    forTag:nil
                                                    adUnit:nil
                                            andAuctionType:0
                                            withCompletion:^(BOOL result) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    __strong __typeof(&*weakSelf)strongSelf = weakSelf;
                                                    strongSelf.fileCached = result;
                                                    completion(result);
                                                    });
                                            }
                              ];
}

- (NSString *) filePathForCachedVideo {
    // starts with `imp` because HZDownloadHelper wants it to
    NSString *filename = [NSString stringWithFormat: @"imp.vast.%@.%@", [HZUtils MD5ForString:[self.sourceURL absoluteString]], self.fileExtension];
    return [HZUtils cacheDirectoryWithFilename: filename];
}

- (NSURL *) URLForVideo {
    if (self.fileCached) {
        return [NSURL fileURLWithPath: [self filePathForCachedVideo]];
    } else {
        return self.sourceURL;
    }
}

-(void) setFileCached:(BOOL)fileCached {
    _fileCached = fileCached;
    [self.delegate videoCached:fileCached];
}

@end