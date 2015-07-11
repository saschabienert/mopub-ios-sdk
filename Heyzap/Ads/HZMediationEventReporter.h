//
//  HZMediationSession.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

@interface HZMediationEventReporter : NSObject

@property (nonatomic, readonly) HZAdType adType;
@property (nonatomic, readonly) NSString *adUnit;
@property (nonatomic, strong, readonly) NSString *tag;
@property (nonatomic, strong, readonly) NSString *impressionID;

/**
 *  Initializes an event reporter
 *
 *  @param json              The /mediate response. Required.
 *  @param mediateParams     The params used for /mediate. Required
 *  @param potentialAdapters The adapters we might use for the show.
 *  @param adType            The adType of the show.
 *  @param tag               The tag for the show.
 *  @param error             An out-pointer for an error reading the JSON.
 *
 *  @return The HZMediationEventReporter, or nil if there was an error.
 */
- (instancetype)initWithJSON:(NSDictionary *)json mediateParams:(NSDictionary *)mediateParams potentialAdapters:(NSOrderedSet *)potentialAdapters adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error;

// ** Querying the session **

//- (HZBaseAdapter *)firstAdapterWithAd:(NSDate *const)lastInterstitialVideoShown;

/**
 *  Returns the available adapters, taking into account the last time an interstitial ad was served by a video-only network.
 *
 *  @param lastInterstitialVideoShown The date a video-only network served an interstitial, or `nil` if none has been shown.
 *
 *  @return The adapters.
 */
//- (NSOrderedSet *)availableAdapters:(NSDate *const)lastInterstitialVideoShown;

//- (BOOL)adapterIsRateLimited:(HZBaseAdapter *const)adapter lastInterstitialVideoShown:(NSDate *const)lastInterstitialVideoShown;

#pragma mark - Reporting Events to the server

- (void)reportFetchWithSuccessfulAdapter:(HZBaseAdapter *)chosenAdapter;

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter;

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter;

- (void)reportIncentivizedResult:(BOOL)success forAdapter:(HZBaseAdapter *)adapter;

@end
