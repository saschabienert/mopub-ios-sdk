//
//  HZMediationSession.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

@interface HZMediationSession : NSObject

@property (nonatomic, strong, readonly) NSOrderedSet *chosenAdapters;
@property (nonatomic, readonly) HZAdType adType;
@property (nonatomic, strong, readonly) NSString *tag;

@property (nonatomic, strong, readonly) NSString *impressionID;

- (instancetype)initWithJSON:(NSDictionary *)json setupMediators:(NSSet *)setupMediators adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error;

- (HZBaseAdapter *)firstAdapterWithAd;

#pragma mark - Reporting Events to the server

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter;

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter;

@end
