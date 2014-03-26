//
//  HZChartboostClassProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/24/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZClassProxy.h"

typedef enum {
    HZCBLoadErrorInternal,
    HZCBLoadErrorInternetUnavailable,
    HZCBLoadErrorTooManyConnections, /**< Too many requests are pending for that location  */
    HZCBLoadErrorWrongOrientation,    /**< Interstitial loaded with wrong orientation */
    HZCBLoadErrorFirstSessionInterstitialsDisabled, /**< Interstitial disabled, first session */
    HZCBLoadErrorNetworkFailure,  /**< Network request failed */
    HZCBLoadErrorNoAdFound,  /**<  No ad received */
    HZCBLoadErrorSessionNotStarted, /**< Session not started, use startSession method */
    HZCBLoadErrorAgeGateFailure,  /**< User failed to pass the Age Gate */
} HZCBLoadError;

@interface HZChartboost : HZClassProxy

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *appSignature;
@property (nonatomic, weak) id delegate;

+ (instancetype)sharedChartboost;

- (void)startSession;

- (void)cacheInterstitial;

- (BOOL)hasCachedInterstitial;

- (void)showInterstitial;


@end
