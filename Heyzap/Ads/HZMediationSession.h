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
- (instancetype)initWithJSON:(NSDictionary *)json mediateParams:(NSDictionary *)mediateParams setupMediators:(NSSet *)setupMediators adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error;

// ** Querying the session **

- (HZBaseAdapter *)firstAdapterWithAd:(NSDate *const)lastInterstitialVideoShown;

/**
 *  Returns the available adapters, taking into account the last time an interstitial ad was served by a video-only network.
 *
 *  @param lastInterstitialVideoShown The date a video-only network served an interstitial, or `nil` if none has been shown.
 *
 *  @return The adapters.
 */
- (NSOrderedSet *)availableAdapters:(NSDate *const)lastInterstitialVideoShown;

- (BOOL)adapterIsRateLimited:(HZBaseAdapter *const)adapter lastInterstitialVideoShown:(NSDate *const)lastInterstitialVideoShown;

#pragma mark - Reporting Events to the server

- (void)reportSuccessfulFetchUpToAdapter:(HZBaseAdapter *)chosenAdapter;

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter;

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter;

@end
