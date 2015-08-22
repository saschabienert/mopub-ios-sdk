//
//  HZMediationLoadManager.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/17/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZCreativeType.h"

@class HZShowOptions;
@class HZBaseAdapter;
@protocol HZMediationPersistentConfigReadonly;

@protocol HZMediationLoadManagerDelegate <NSObject>

- (BOOL)setupAdapterNamed:(NSString *)adapterName;
- (void)didFetchAdOfCreativeType:(HZCreativeType)creativeType withAdapter:(HZBaseAdapter *)adapter options:(HZShowOptions *)showOptions;
- (void)didFailToFetchAdOfCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)showOptions;
- (dispatch_queue_t)pausableMainQueue;

@end

@interface HZMediationLoadManager : NSObject

- (instancetype)initWithLoadData:(NSDictionary *)loadData delegate:(id<HZMediationLoadManagerDelegate>)delegate persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig error:(NSError **)error;
- (void)fetchCreativeType:(HZCreativeType)creativeType showOptions:(HZShowOptions *)showOptions optionalForcedNetwork:(Class)forcedNetwork notifyDelegate:(BOOL)notifyDelegate;

@end
