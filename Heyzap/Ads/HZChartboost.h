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
    CBLoadErrorInternal,
    CBLoadErrorInternetUnavailable,
    CBLoadErrorTooManyConnections, /**< Too many requests are pending for that location  */
    CBLoadErrorWrongOrientation,    /**< Interstitial loaded with wrong orientation */
    CBLoadErrorFirstSessionInterstitialsDisabled, /**< Interstitial disabled, first session */
    CBLoadErrorNetworkFailure,  /**< Network request failed */
    CBLoadErrorNoAdFound,  /**<  No ad received */
    CBLoadErrorSessionNotStarted, /**< Session not started, use startSession method */
    CBLoadErrorAgeGateFailure,  /**< User failed to pass the Age Gate */
} CBLoadError;

@interface HZChartboost : HZClassProxy

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *appSignature;
@property (nonatomic, weak) id delegate;

+ (instancetype)sharedChartboost;

- (void)startSession;

- (void)cacheInterstitial:(NSString *)location;

- (BOOL)hasCachedInterstitial:(NSString *)location;

- (void)showInterstitial:(NSString *)location;


@end
