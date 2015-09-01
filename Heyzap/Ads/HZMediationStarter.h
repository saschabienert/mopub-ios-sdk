//
//  HZMediationStarter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 5/5/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HZCachingService;

typedef NS_ENUM(NSUInteger, HZMediationStartStatus) {
    HZMediationStartStatusNotStarted,
    HZMediationStartStatusSuccess,
};

NS_ASSUME_NONNULL_BEGIN

@protocol HZMediationStarting <NSObject>

- (void)startWithDictionary:(NSDictionary *)dictionary fromCache:(BOOL)fromCache;
- (void)receivedStartHeaders:(NSDictionary *)headers;

@end

@interface HZMediationStarter : NSObject

- (instancetype)initWithStartingDelegate:(id<HZMediationStarting>)startingDelegate cachingService:(HZCachingService *)cachingService NS_DESIGNATED_INITIALIZER;

- (void)start;

#pragma mark - Testing

+ (NSString *)startFilename;

@end

NS_ASSUME_NONNULL_END
