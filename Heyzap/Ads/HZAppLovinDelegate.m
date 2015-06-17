//
//  AppLovinDelegate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAppLovinDelegate.h"
#import "HZIncentivizedAppLovinDelegate.h"
#import "HZBaseAdapter.h"
#import "HZAppLovinAdapter.h"
#import "HZMediationConstants.h"


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
- (instancetype) init{
    self = [super init];
    if(self){
        _playbackState = HZAppLovinRewardedAdPlaybackStateNotStarted;
        _validationState = HZAppLovinRewardedAdValidationStateWaiting;
    }
    return self;
}
@end

@interface HZAppLovinDelegate()

@property (nonatomic) HZAdType adType;
@property (nonatomic) NSMutableDictionary *adStateDictionary;

@end

@implementation HZAppLovinDelegate

- (id)initWithAdType:(HZAdType)adType delegate:(id<HZAppLovinDelegateReceiver>)delegate
{
    self = [super init];
    if (self) {
        
        _adType = adType;
        _delegate = delegate;
        _adStateDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - App Lovin Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"ALAdLoadDelegate"]) {
        return YES;
    } else if ([NSStringFromProtocol(aProtocol) isEqualToString:@"ALAdDisplayDelegate"]) {
        return YES;
    } else if ([NSStringFromProtocol(aProtocol) isEqualToString:@"HZALAdVideoPlaybackDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

#pragma mark - Ad Load Delegate

- (void)adService:(HZALAdService *)adService didLoadAd:(HZALAd *)ad
{
    [self.delegate didLoadAdOfType:self.adType];
}

- (void)adService:(HZALAdService *)adService didFailToLoadAdWithError:(int)code
{
    [self.delegate didFailToLoadAdOfType:self.adType
                                   error:[NSError errorWithDomain:kHZMediationDomain code:code userInfo:nil]];
}

#pragma mark - Display Delegate

- (void)ad:(HZALAd *)ad wasDisplayedIn:(UIView *)view
{
    [self.delegate didShowAd];
}

- (void)ad:(HZALAd *)ad wasHiddenIn:(UIView *)view
{
    [self.delegate didDismissAd];
}

- (void)ad:(HZALAd *)ad wasClickedIn:(UIView *)view
{
    [self.delegate didClickAd];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(HZALAd *)ad
{
    [self.delegate willPlayAudio];
    
    HZAppLovinRewardedAdState * state = [self.adStateDictionary objectForKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    if(!state){
        state = [[HZAppLovinRewardedAdState alloc] init];
        [self.adStateDictionary setObject:state forKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    }
}

- (void)videoPlaybackEndedInAd:(HZALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched
{
    [self.delegate didFinishAudio];

    HZAppLovinRewardedAdState * state = [self.adStateDictionary objectForKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    if(!state) {
        HZDLog(@"HZAppLovinDelegate: video playback ended but ad reference was not saved successfully when playback began.");
        return;
    }
    
    state.playbackState = HZAppLovinRewardedAdPlaybackStateFinished;
    [self notifyDelegateIfApplicableForAd:ad withState:state];
}

- (void) rewardValidationResult:(BOOL)success forAd:(HZALAd *)ad
{
    HZAppLovinRewardedAdState * state = [self.adStateDictionary objectForKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    if(!state) {
        state = [[HZAppLovinRewardedAdState alloc] init];
        state.validationState = (success ? HZAppLovinRewardedAdValidationStateSuccessful : HZAppLovinRewardedAdValidationStateFailed);
        [self.adStateDictionary setObject:state forKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    }else{
        state.validationState = (success ? HZAppLovinRewardedAdValidationStateSuccessful : HZAppLovinRewardedAdValidationStateFailed);
    }

    [self notifyDelegateIfApplicableForAd:ad withState:state];
}

-(void)userDeclinedToViewAppLovinIncentivizedAd:(HZALAd *)ad {
    // user declined to view an ad - treat it as a validation failure but first remember
    // the video will never complete so the dict entry is removed
    HZAppLovinRewardedAdState * state = [self.adStateDictionary objectForKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    if(!state){
        state = [[HZAppLovinRewardedAdState alloc] init];
        state.playbackState = HZAppLovinRewardedAdPlaybackStateWontFinish;
        [self.adStateDictionary setObject:state forKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    }else{
        state.playbackState = HZAppLovinRewardedAdPlaybackStateWontFinish;
    }
    
    [self rewardValidationResult:NO forAd:ad];
}

- (void) notifyDelegateIfApplicableForAd:(HZALAd *)ad withState:(HZAppLovinRewardedAdState *)state{
    if([self isKindOfClass:[HZIncentivizedAppLovinDelegate class]]){
        if(state.validationState == HZAppLovinRewardedAdValidationStateSuccessful && state.playbackState == HZAppLovinRewardedAdPlaybackStateFinished){
            [self.delegate didCompleteIncentivized];
        }else if(state.validationState == HZAppLovinRewardedAdValidationStateFailed){
            [self.delegate didFailToCompleteIncentivized];
        }
    }
    
    // remove dict entry for ad if there won't be any more messages to send about it
    if(state.validationState != HZAppLovinRewardedAdValidationStateWaiting && state.playbackState != HZAppLovinRewardedAdPlaybackStateNotStarted){
        [self.adStateDictionary removeObjectForKey:[HZAppLovinDelegate adStatusDictionaryKeyForAd:ad]];
    }
}

+ (NSValue *) adStatusDictionaryKeyForAd:(HZALAd *)ad{
    return [NSValue valueWithNonretainedObject:ad];
}

@end
