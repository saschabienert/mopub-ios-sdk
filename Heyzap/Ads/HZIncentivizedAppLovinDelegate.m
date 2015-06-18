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

/* Pointer to this char is used as a unique key for the state stored as an associated object on the HZALAd*/
static char adStatusKey;

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
    
    state.playbackState = HZAppLovinRewardedAdPlaybackStateFinished;
    [self notifyDelegateIfApplicableForAd:ad withState:state];
}

#pragma mark - Success conditions from AppLovin

- (void)rewardValidationRequestForAd:(HZALAd *)ad didSucceedWithResponse:(NSDictionary *)response {
    ensureMainQueue(^{
        [self rewardValidationResult:YES forAd:ad];
    });
}

#pragma mark - Failure conditions from AppLovin

/*
 * This method will be invoked if we were able to contact AppLovin, but the user has already received
 * the maximum number of coins you allowed per day in the web UI.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad didExceedQuotaWithResponse:(NSDictionary *)response {
    ensureMainQueue(^{
        [self rewardValidationResult:NO forAd:ad];
    });
}

/*
 * This method will be invoked if the AppLovin server rejected the reward request.
 * This would usually happen if the user fails to pass an anti-fraud check.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad wasRejectedWithResponse:(NSDictionary *)response {
    ensureMainQueue(^{
        [self rewardValidationResult:NO forAd:ad];
    });
}

/*
 * This method will be invoked if were unable to contact AppLovin, so no ping will be heading to your server.
 */
- (void)rewardValidationRequestForAd:(HZALAd *)ad didFailWithError:(NSInteger)responseCode {
    ensureMainQueue(^{
        [self rewardValidationResult:NO forAd:ad];
    });
}

/*
 * This method will be invoked if the user chooses 'no' when asked if they want to view a rewarded video.
 */
- (void)userDeclinedToViewAd:(HZALAd *)ad {
    ensureMainQueue(^{
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
    if(state.validationState == HZAppLovinRewardedAdValidationStateSuccessful && state.playbackState == HZAppLovinRewardedAdPlaybackStateFinished){
        // only send completion message once the video is finished and the reward is validated
        [self.delegate didCompleteIncentivized];
    }else if(state.validationState == HZAppLovinRewardedAdValidationStateFailed){
        // immediately send failure message when validation fails
        [self.delegate didFailToCompleteIncentivized];
    }
    
    // remove state from ad if there won't be any more messages to send about it
    if(state.validationState != HZAppLovinRewardedAdValidationStateWaiting && state.playbackState != HZAppLovinRewardedAdPlaybackStateNotFinished){
        [HZIncentivizedAppLovinDelegate setAdState:nil forAd:ad];
    }
}

#pragma mark - Helper methods

+ (HZAppLovinRewardedAdState *) adStateForAd:(HZALAd *)ad {
    return objc_getAssociatedObject(ad, &adStatusKey);
}

+ (void) setAdState:(HZAppLovinRewardedAdState *)state forAd:(HZALAd *)ad {
    objc_setAssociatedObject(ad, &adStatusKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
