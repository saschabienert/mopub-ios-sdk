//
//  HZVASTVideoCache.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/24/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//


#import <Foundation/Foundation.h>


@protocol HZVastVideoCacheDelegate <NSObject>
-(void)videoCached:(BOOL)success;
@end

@interface HZVASTVideoCache : NSObject

@property (nonatomic, readonly) BOOL fileCached;
@property (nonatomic, weak) id<HZVastVideoCacheDelegate>delegate;
- (void) startCaching:(NSURL *)sourceURL withCompletion:(void (^)(BOOL))completion;
- (NSURL *) URLForVideo;

@end
