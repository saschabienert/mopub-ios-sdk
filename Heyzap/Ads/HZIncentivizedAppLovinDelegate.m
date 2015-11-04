//
//  HZIncentivizedAppLovinDelegate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/14/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <objc/runtime.h>
#import "HZIncentivizedAppLovinDelegate.h"
#import "HZAppLovinAdapter.h"
#import "HZDispatch.h"

/** Pointer to this char is used as a unique key for the state stored as an associated object on the HZALAd*/
static char adStatusKey;

/** A pointer to this char is used as a unique key for storing whether we've sent an incentivized callback for a given HZALAd. */
static char adHasSentIncentivizedCallbackKey;

@interface HZAppLovinRewardedAdState:NSObject

typedef NS_ENUM(NSInteger, HZAppLovinRewardedAdPlaybackState) {
    HZAppLovinRewardedAdPlaybackStateNotFinished,
    HZAppLovinRewardedAdPlaybackStateFinished,
    HZAppLovinRewardedAdPlaybackStateWontFinish
};

typedef NS_ENUM(NSInteger, HZAppLovinRewardedAdValidationState) {
    HZAppLovinRewardedAdValidationStateWaiting,
    HZAppLovinRewardedAdValidationStateSuccessful,
    HZAppLovinRewardedAdValidationStateFailed
};

@property (nonatomic) HZAppLovinRewardedAdPlaybackState playbackState;
@property (nonatomic) HZAppLovinRewardedAdValidationState validationState;

@end

@implementation HZAppLovinRewardedAdState
- (instancetype)init {
    self = [super init];
    if(self){
        _playbackState = HZAppLovinRewardedAdPlaybackStateNotFinished;
        _validationState = HZAppLovinRewardedAdValidationStateWaiting;
    }
    return self;
}
@end

@implementation HZIncentivizedAppLovinDelegate

#pragma mark - Overridden AppLovin callbacks from HZAppLovinDelegate

- (void)videoPlaybackBeganInAd:(HZALAd *)ad {
    [super videoPlaybackBeganInAd:ad];
    
    HZAppLovinRewardedAdState * state = [HZIncentivizedAppLovinDelegate adStateForAd:ad];
    if(!state){
        state = [[HZAppLovinRewardedAdState alloc] init];
        [HZIncentivizedAppLovinDelegate setAdState:state forAd:ad];
    }
}

- (void)videoPlaybackEndedInAd:(HZALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched {
    [super videoPlaybackEndedInAd:ad atPlaybackPercent:percentPlayed fullyWatched:wasFullyWatched];
    
    HZAppLovinRewardedAdState * state = [HZIncentivizedAppLovinDelegate adStateForAd:ad];
    if(!state) {
        HZELog(@"HZAppLovinDelegate: video playback ended but ad reference was not saved successfully when playback began.");
        return;
    }
    
    if (!wasFullyWatched) {
        state.validationState = HZAppLovinRewardedAdValidationStateFailed;
    }
    
    state.playbackState = wasFullyWatched ? HZAppLovinRewardedAdPlaybackStateFinished : HZAppLovinRewardedAdPlaybackStateWontFinish;
    [self notifyDelegateIfApplicableForAd:ad withState:state];
}

#pragma mark - Success conditions from AppLovin

// WARNING: AppLovin will send `rewardValidationRequestForAd:didSucceedWithResponse:` and then later `rewardValidationRequestForAd:didFailWithError:`. Search their rewarded video docs (https://www.applovin.com/integration#iosRewardedVids) for `kALErrorCodeIncentivizedUserClosedVideo`.
- (void)rewardValidationRequestForAd:(HZALAd *)ad didSucceedWithResponse:(NSDictionary *)response {
    hzEnsureMainQueue(^{
        [self rewardValidationResult:YES forAd:ad];
    });
}

#pragma mark - Failure conditions from AppLovin

/*
 * This method will be invoked if we were able to contact AppLovin, but the user has already received
 * the maximum number of coins you allowed per day in the web UI.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad didExceedQuotaWithResponse:(NSDictionary *)response {
    hzEnsureMainQueue(^{
        [self rewardValidationResult:NO forAd:ad];
    });
}

/*
 * This method will be invoked if the AppLovin server rejected the reward request.
 * This would usually happen if the user fails to pass an anti-fraud check.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad wasRejectedWithResponse:(NSDictionary *)response {
    hzEnsureMainQueue(^{
        [self rewardValidationResult:NO forAd:ad];
    });
}

/*
 * This method will be invoked if were unable to contact AppLovin, so no ping will be heading to your server.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad didFailWithError:(NSInteger)responseCode {
    hzEnsureMainQueue(^{
        [self rewardValidationResult:NO forAd:ad];
    });
}

/*
 * This method will be invoked if the user chooses 'no' when asked if they want to view a rewarded video.
 */
- (void)userDeclinedToViewAd:(HZALAd *)ad {
    hzEnsureMainQueue(^{
        // user declined to view an ad - treat it as a validation failure but first remember
        // the video will never complete so the dict entry is removed
        HZAppLovinRewardedAdState * state = [HZIncentivizedAppLovinDelegate adStateForAd:ad];
        if(!state){
            state = [[HZAppLovinRewardedAdState alloc] init];
            state.playbackState = HZAppLovinRewardedAdPlaybackStateWontFinish;
            [HZIncentivizedAppLovinDelegate setAdState:state forAd:ad];
        }else{
            state.playbackState = HZAppLovinRewardedAdPlaybackStateWontFinish;
        }
        
        [self rewardValidationResult:NO forAd:ad];
    });
}

#pragma mark - Warnings about AppLovin Incentivized Callbacks

// Success-then-Failure callbacks: Note that AppLovin will send `rewardValidationRequestForAd:didSucceedWithResponse:` followed by `rewardValidationRequestForAd:wasRejectedWithResponse:` if the user closes the incentivized video† (This is documented as correct behavior at https://www.applovin.com/integration#iosRewardedVids (search "kALErrorCodeIncentivizedUserClosedVideo")).
// To handle this case, we check in `videoPlaybackEndedInAd:atPlaybackPercent:fullyWatched:` if `fullyWatched` is NO, and if so treat that as incentivized failure.
// Since we get "reward success", "playback began", "playback ended", "reward failed" as the chain of callbacks, it can be tricky to prevent sending duplicate callbacks. To workaround this we use an associated object on the ad (see `hasAdSentCallback:`).

// † You can get an X button to appear during an incentivized video by pressing the home button, then returning to the app.

// Callback Ordering:: AppLovin's incentivized callbacks are validated over the network, and are on a different thread than the video success callbacks, so the order the callbacks arrive is non-deterministic.


#pragma mark - Processing AppLovin callbacks

- (void) rewardValidationResult:(BOOL)success forAd:(HZALAd *)ad {
    HZAppLovinRewardedAdState * state = [HZIncentivizedAppLovinDelegate adStateForAd:ad];
    if(!state) {
        state = [[HZAppLovinRewardedAdState alloc] init];
        state.validationState = (success ? HZAppLovinRewardedAdValidationStateSuccessful : HZAppLovinRewardedAdValidationStateFailed);
        [HZIncentivizedAppLovinDelegate setAdState:state forAd:ad];
    }else{
        state.validationState = (success ? HZAppLovinRewardedAdValidationStateSuccessful : HZAppLovinRewardedAdValidationStateFailed);
    }
    
    [self notifyDelegateIfApplicableForAd:ad withState:state];
}

- (void) notifyDelegateIfApplicableForAd:(HZALAd *)ad withState:(HZAppLovinRewardedAdState *)state {
    if (state.validationState == HZAppLovinRewardedAdValidationStateSuccessful && state.playbackState == HZAppLovinRewardedAdPlaybackStateFinished) {
        // only send completion message once the video is finished and the reward is validated
        [self sendIncentivizedCallbackForAd:ad incentivizedSuccess:YES];
    } else if (state.validationState == HZAppLovinRewardedAdValidationStateFailed) {
        // immediately send failure message when validation fails
        [self sendIncentivizedCallbackForAd:ad incentivizedSuccess:NO];
    }
}

- (void)sendIncentivizedCallbackForAd:(HZALAd *)ad incentivizedSuccess:(BOOL)wasSuccessful {
    if (![[self class] hasAdSentCallback:ad]) {
        if (wasSuccessful) {
            [self.delegate didCompleteIncentivized];
        } else {
            [self.delegate didFailToCompleteIncentivized];
        }
    }
    [[self class] setHasSentCallbackForAd:ad];
}

#pragma mark - Helper methods

+ (HZAppLovinRewardedAdState *) adStateForAd:(HZALAd *)ad {
    return objc_getAssociatedObject(ad, &adStatusKey);
}

+ (void) setAdState:(HZAppLovinRewardedAdState *)state forAd:(HZALAd *)ad {
    objc_setAssociatedObject(ad, &adStatusKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)hasAdSentCallback:(HZALAd *)ad {
    NSNumber *hasSentCallback = objc_getAssociatedObject(ad, &adHasSentIncentivizedCallbackKey);
    return [hasSentCallback isEqual:@YES];
}

+ (void)setHasSentCallbackForAd:(HZALAd *)ad {
    objc_setAssociatedObject(ad, &adHasSentIncentivizedCallbackKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
