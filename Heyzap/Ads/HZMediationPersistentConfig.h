//
//  HZPersistentMediationConfig.h
//  Heyzap
//
//  Created by Maximilian Tagher on 8/20/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HZMediationPersistentConfigReadonly <NSObject>

- (BOOL)isNetworkEnabled:(NSString *)networkName;
- (BOOL)isNetworkDisabled:(NSString *)networkName;
- (NSSet *) allDisabledNetworks;

@end

@class HZCachingService;

/**
 *  Stores mediation configuration that is persisted to disk (on a background queue).
 */
@interface HZMediationPersistentConfig : NSObject <HZMediationPersistentConfigReadonly>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCachingService:(HZCachingService *)cachingService isTestApp:(BOOL)isTestApp NS_DESIGNATED_INITIALIZER;

#pragma mark - Support for disabling networks from the client

- (void)addDisabledNetwork:(NSString *)disabledNetwork;
- (void)addDisabledNetworks:(NSSet *)disabledNetworks;
- (void)removeDisabledNetwork:(NSString *)networkName;
- (void)removeDisabledNetworks:(NSSet *)networks;

@end

NS_ASSUME_NONNULL_END