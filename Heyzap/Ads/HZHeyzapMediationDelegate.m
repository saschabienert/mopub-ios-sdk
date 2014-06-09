//
//  HZHeyzapMediationDelegate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/18/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapMediationDelegate.h"
#import "HZMediationConstants.h"

#import "HZHeyzapIncentivizedAd.h"
#import "HZHeyzapInterstitialAd.h"
#import "HZHeyzapVideoAd.h"

@interface HZHeyzapMediationDelegate()

@property (nonatomic) HZAdType adType;
@property (nonatomic, weak) id<HZHeyzapDelegateReceiver> delegate;

@end

@implementation HZHeyzapMediationDelegate

- (id)initWithAdType:(HZAdType)adType delegate:(id<HZHeyzapDelegateReceiver>)delegate
{
    NSParameterAssert(delegate);
    self = [super init];
    if (self) {
        _adType = adType;
        _delegate = delegate;
        [self becomeDelegateForType:adType];
    }
    return self;
}

- (void)becomeDelegateForType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            [HZHeyzapInterstitialAd setDelegate:self];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZHeyzapIncentivizedAd setDelegate:self];
            break;
        }
        case HZAdTypeVideo: {
            [HZHeyzapVideoAd setDelegate:self];
            break;
        }
    }
}

- (void)didFailToShowAdWithTag:(NSString *)tag andError:(NSError *)error
{
    [self.delegate didDismissAd];
}

- (void)didFailToReceiveAdWithTag: (NSString *) tag
{
    [self.delegate didFailToLoadAdOfType:self.adType
                                   error:[NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil]];
}

- (void)didClickAdWithTag: (NSString *) tag
{
    [self.delegate didClickAd];
}

- (void)didHideAdWithTag: (NSString *) tag
{
    [self.delegate didDismissAd];
}

#pragma mark - Incentivized

- (void)didCompleteAd
{
    [self.delegate didCompleteIncentivizedAd];
}

- (void)didFailToCompleteAd
{
    [self.delegate didFailToCompleteIncentivizedAd];
}

#pragma mark - Audio

- (void)willStartAudio
{
    [self.delegate willPlayAudio];
}

- (void)didFinishAudio
{
    [self.delegate didFinishPlayingAudio];
}
@end
