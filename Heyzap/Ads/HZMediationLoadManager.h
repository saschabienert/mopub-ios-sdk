//
//  HZMediationLoadManager.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"

@class HZShowOptions;
@protocol HZMediationPersistentConfigReadonly;

@protocol HZMediationLoadManagerDelegate <NSObject>

- (BOOL)setupAdapterNamed:(NSString *)adapterName;
- (void)didFetchAdOfType:(HZAdType)adType options:(HZShowOptions *)showOptions;
- (void)didFailToFetchAdOfType:(HZAdType)adType options:(HZShowOptions *)showOptions;
- (dispatch_queue_t)pausableMainQueue;

@end

@interface HZMediationLoadManager : NSObject

- (instancetype)initWithLoadData:(NSDictionary *)loadData delegate:(id<HZMediationLoadManagerDelegate>)delegate persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig error:(NSError **)error;
- (void)fetchAdType:(HZAdType)adType showOptions:(HZShowOptions *)showOptions optionalForcedNetwork:(Class)forcedNetwork;

@end
