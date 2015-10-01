//
//  HZMediationLoadManager.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZCreativeType.h"

@class HZFetchOptions;
@class HZBaseAdapter;
@class HZSegmentationController;
@protocol HZMediationPersistentConfigReadonly;

@protocol HZMediationLoadManagerDelegate <NSObject>

- (BOOL)setupAdapterNamed:(NSString *)adapterName;
- (BOOL)isNetworkClassInitialized:(Class)networkClass;
- (NSSet *)availableAdaptersWithHeyzap:(BOOL)includeHeyzap;
- (void)didFetchAdOfCreativeType:(HZCreativeType)creativeType withAdapter:(HZBaseAdapter *)adapter options:(HZFetchOptions *)fetchOptions;
- (void)didFailToFetchAdOfCreativeType:(HZCreativeType)creativeType options:(HZFetchOptions *)fetchOptions;
- (dispatch_queue_t)pausableMainQueue;

@end

@interface HZMediationLoadManager : NSObject

- (instancetype)initWithLoadData:(NSDictionary *)loadData delegate:(id<HZMediationLoadManagerDelegate>)delegate persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig segmentationController:( HZSegmentationController *)segmentationController error:(NSError **)error;
- (BOOL) refreshWithLoadData:(NSDictionary *)loadData error:(NSError **)error;

- (void)fetchCreativeType:(HZCreativeType)creativeType fetchOptions:(HZFetchOptions *)fetchOptions optionalForcedNetwork:(Class)forcedNetwork notifyDelegate:(BOOL)notifyDelegate;

@end
