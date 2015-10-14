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
@property (nonatomic) NSMutableSet<NSString *> *disabledNetworks;
@property (nonatomic, readonly) BOOL isTestApp;
@property (atomic) NSUInteger writeVersion;
@end

@implementation HZMediationPersistentConfig

- (instancetype)initWithCachingService:(HZCachingService *)cachingService {
    HZParameterAssert(cachingService);
    self = [super init];
    if (self) {
        _cachingService = cachingService;
        _writeVersion = 0;
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

- (NSSet *) allDisabledNetworks {
    return [NSSet setWithSet:[self disabledNetworks]];
}

- (void)addDisabledNetwork:(NSString *)disabledNetwork {
    [self.disabledNetworks addObject:disabledNetwork];
    [self storeNetworksToDisk];
}

- (void)addDisabledNetworks:(NSSet *)disabledNetworks {
    [self.disabledNetworks unionSet:disabledNetworks];
    [self storeNetworksToDisk];
}

- (void)removeDisabledNetwork:(NSString *)networkName {
    [self.disabledNetworks removeObject:networkName];
    [self storeNetworksToDisk];
}

- (void)removeDisabledNetworks:(NSSet *)networks {
    [self.disabledNetworks minusSet:networks];
    [self storeNetworksToDisk];
}

- (BOOL)isNetworkDisabled:(NSString *)networkName {
    return [self.disabledNetworks containsObject:networkName];
}

- (BOOL)isNetworkEnabled:(NSString *)networkName {
    return ![self isNetworkDisabled:networkName];
}

- (void)storeNetworksToDisk {
    // async update should only proceed with write if it's the latest write to avoid overwriting a newer version of the file
    NSUInteger const version = ++self.writeVersion;
    NSSet *disabledNetworksCopy = [self.disabledNetworks copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if(version == self.writeVersion) {
            [self.cachingService cacheRootObject:disabledNetworksCopy filename:[self disabledNetworksFilename]];
        }
    });
}

- (NSString *)disabledNetworksFilename {
    return @"disabledNetworks.plist";
}

@end
