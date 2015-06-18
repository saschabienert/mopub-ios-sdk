//
//  HZIncentivizedAppLovinDelegate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/14/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZIncentivizedAppLovinDelegate.h"
#import "HZAppLovinAdapter.h"
#import "HZDispatch.h"

@interface HZAppLovinRewardedAdState:NSObject

typedef NS_ENUM(NSInteger, HZAppLovinRewardedAdPlaybackState) {
    HZAppLovinRewardedAdPlaybackStateNotStarted,
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
        _playbackState = HZAppLovinRewardedAdPlaybackStateNotStarted;
        _validationState = HZAppLovinRewardedAdValidationStateWaiting;
    }
    return self;
}
@end

@interface HZIncentivizedAppLovinDelegate()
@property (nonatomic) NSMutableDictionary *adStateDictionary;
@end

@implementation HZIncentivizedAppLovinDelegate

- (id)initWithAdType:(HZAdType)adType delegate:(id<HZAppLovinDelegateReceiver>)delegate {
    self = [super initWithAdType:adType delegate:delegate];
    if (self) {
        _adStateDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Overridden AppLovin callbacks from HZAppLovinDelegate

- (void)videoPlaybackBeganInAd:(HZALAd *)ad {
    [super videoPlaybackBeganInAd:ad];
    
    NSValue * dictKey = [HZIncentivizedAppLovinDelegate adStatusDictionaryKeyForAd:ad];
    HZAppLovinRewardedAdState * state = self.adStateDictionary[dictKey];
    if(!state){
        state = [[HZAppLovinRewardedAdState alloc] init];
        self.adStateDictionary[dictKey] = state;
    }
}

- (void)videoPlaybackEndedInAd:(HZALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched {
    [super videoPlaybackEndedInAd:ad atPlaybackPercent:percentPlayed fullyWatched:wasFullyWatched];
    
    NSValue * dictKey = [HZIncentivizedAppLovinDelegate adStatusDictionaryKeyForAd:ad];
    HZAppLovinRewardedAdState * state = self.adStateDictionary[dictKey];
    if(!state) {
        HZDLog(@"HZAppLovinDelegate: video playback ended but ad reference was not saved successfully when playback began.");
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
        NSValue * dictKey = [HZIncentivizedAppLovinDelegate adStatusDictionaryKeyForAd:ad];
        HZAppLovinRewardedAdState * state = self.adStateDictionary[dictKey];
        if(!state){
            state = [[HZAppLovinRewardedAdState alloc] init];
            state.playbackState = HZAppLovinRewardedAdPlaybackStateWontFinish;
            self.adStateDictionary[dictKey] = state;
        }else{
            state.playbackState = HZAppLovinRewardedAdPlaybackStateWontFinish;
        }
        
        [self rewardValidationResult:NO forAd:ad];
    });
}

#pragma mark - Processing AppLovin callbacks

- (void) rewardValidationResult:(BOOL)success forAd:(HZALAd *)ad {
    NSValue * dictKey = [HZIncentivizedAppLovinDelegate adStatusDictionaryKeyForAd:ad];
    HZAppLovinRewardedAdState * state = self.adStateDictionary[dictKey];
    if(!state) {
        state = [[HZAppLovinRewardedAdState alloc] init];
        state.validationState = (success ? HZAppLovinRewardedAdValidationStateSuccessful : HZAppLovinRewardedAdValidationStateFailed);
        self.adStateDictionary[dictKey] = state;
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
    
    // remove dict entry for ad if there won't be any more messages to send about it
    // this prevents duplicate messages being sent for an ad (& frees memory)
    if(state.validationState != HZAppLovinRewardedAdValidationStateWaiting && state.playbackState != HZAppLovinRewardedAdPlaybackStateNotStarted){
        NSValue * dictKey = [HZIncentivizedAppLovinDelegate adStatusDictionaryKeyForAd:ad];
        [self.adStateDictionary removeObjectForKey:dictKey];
    }
}

#pragma mark - Helper methods

+ (NSValue *) adStatusDictionaryKeyForAd:(HZALAd *)ad {
    return [NSValue valueWithNonretainedObject:ad];
}

@end
