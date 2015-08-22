//
//  HZPersistentMediationConfig.m
//  Heyzap
//
//  Created by Maximilian Tagher on 8/20/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationPersistentConfig.h"
#import "HZDevice.h"
#import "HZCachingService.h"

@interface HZMediationPersistentConfig()

@property (nonatomic, readonly) HZCachingService *cachingService;
@property (nonatomic) NSMutableSet *disabledNetworks;
@property (nonatomic, readonly) BOOL isTestApp;

@end

@implementation HZMediationPersistentConfig

- (instancetype)initWithCachingService:(HZCachingService *)cachingService isTestApp:(BOOL)isTestApp {
    HZParameterAssert(cachingService);
    self = [super init];
    if (self) {
        _cachingService = cachingService;
        _isTestApp = isTestApp;
    }
    return self;
}

- (NSMutableSet *)disabledNetworks {
    if (!_disabledNetworks) {
        NSSet *const cachedNetworks = [self.cachingService rootObjectWithFilename:[self disabledNetworksFilename]];
        _disabledNetworks = [cachedNetworks mutableCopy] ?: [NSMutableSet set];
    }
    return _disabledNetworks;
}

- (void)addDisabledNetwork:(NSString *)disabledNetwork {
    if (!self.isTestApp) {
        return;
    }
    
    [self.disabledNetworks addObject:disabledNetwork];
    [self storeNetworksToDisk];
}

- (void)removeDisabledNetwork:(NSString *)networkName {
    if (!self.isTestApp) {
        return;
    }
    
    [self.disabledNetworks removeObject:networkName];
    [self storeNetworksToDisk];
}

- (BOOL)isNetworkDisabled:(NSString *)networkName {
    if (self.isTestApp) {
        return [self.disabledNetworks containsObject:networkName];
    } else {
        return NO;
    }
}

- (BOOL)isNetworkEnabled:(NSString *)networkName {
    return ![self isNetworkDisabled:networkName];
}

- (void)storeNetworksToDisk {
    NSSet *disabledNetworksCopy = [self.disabledNetworks copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self.cachingService cacheRootObject:disabledNetworksCopy filename:[self disabledNetworksFilename]];
    });
}

- (NSString *)disabledNetworksFilename {
    return @"disabledNetworks.plist";
}

@end
