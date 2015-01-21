//
//  HZMediationSession.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"
#import "HZMetrics.h"

@interface HZMediationSession : NSObject <HZMetricsProvider>

@property (nonatomic, strong, readonly) NSOrderedSet *chosenAdapters;
@property (nonatomic, readonly) HZAdType adType;
@property (nonatomic, readonly) NSString *adUnit;
@property (nonatomic, strong, readonly) NSString *tag;

@property (nonatomic, strong, readonly) NSString *impressionID;

/**
 *  Initializes a session.
 *
 *  @param json           The JSON from the server. Required.
 *  @param setupMediators Currently setup adapters. Required.
 *  @param adType         Required
 *  @param tag            Required.
 *  @param error          Out param signalling there was an error. Must not be NULL.
 *
 *  @return nil if there was an error, otherwise a valid session.
 */
- (instancetype)initWithJSON:(NSDictionary *)json setupMediators:(NSSet *)setupMediators adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error;

- (HZBaseAdapter *)firstAdapterWithAd;

- (BOOL)hasAd;

/**
 *  Call this method when we use a video only network to show an interstitial.
 */
+ (void)usedVideoOnlyNetworkForInterstitial;

#pragma mark - Reporting Events to the server

- (void)reportSuccessfulFetchUpToAdapter:(HZBaseAdapter *)chosenAdapter;

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter;

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter;

@end
