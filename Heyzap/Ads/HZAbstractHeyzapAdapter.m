//
//  HZAbstractHeyzapAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/4/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAbstractHeyzapAdapter.h"
#import "HZHeyzapIncentivizedAd.h"
#import "HZHeyzapInterstitialAd.h"
#import "HZHeyzapVideoAd.h"
#import "HeyzapMediation.h"
#import "HZMediationConstants.h"

@implementation HZAbstractHeyzapAdapter

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable
{
    return YES;
}

+ (BOOL)isHeyzapAdapter {
    return YES;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    return nil;
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeInterstitial | HZAdTypeVideo | HZAdTypeIncentivized;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    const HZAuctionType auctionType = [self auctionType];
    switch (type) {
        case HZAdTypeInterstitial: {
            [HZHeyzapInterstitialAd fetchForTag:tag auctionType:auctionType withCompletion:nil];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZHeyzapIncentivizedAd fetchForTag:tag auctionType:auctionType completion:nil];
            break;
        }
        case HZAdTypeVideo: {
            [HZHeyzapVideoAd fetchForTag:tag auctionType:auctionType withCompletion:nil];
            break;
        }
    }
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    const HZAuctionType auctionType = [self auctionType];
    if (type & HZAdTypeVideo) {
        return [HZHeyzapVideoAd isAvailableForTag:tag auctionType:auctionType];
    } else if (type & HZAdTypeInterstitial) {
        return [HZHeyzapInterstitialAd isAvailableForTag:tag auctionType:auctionType];
    } else  {
        return [HZHeyzapIncentivizedAd isAvailableForTag:tag auctionType:auctionType];
    }
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    const HZAuctionType auctionType = [self auctionType];
    switch (type) {
        case HZAdTypeInterstitial: {
            [HZHeyzapInterstitialAd showForTag:tag auctionType:auctionType completion:nil];
            break;
        }
        case HZAdTypeIncentivized: {
            [HZHeyzapIncentivizedAd showForTag:tag auctionType:auctionType];
            break;
        }
        case HZAdTypeVideo: {
            [HZHeyzapVideoAd showForTag:tag auctionType:auctionType completion:nil];
            break;
        }
    }
}

#pragma mark - NSNotificationCenter registering

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToShowAd:) name:kHeyzapDidFailToShowAdNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAd:) name:kHeyzapDidReceiveAdNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToReceiveAd:) name:kHeyzapDidFailToReceiveAdNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didClickAd:) name:kHeyzapDidClickAdNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideAd:) name:kHeyzapDidHideAdNotification object:nil];
        
        // Audio
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willStartAudio:) name:kHeyzapWillStartAudio object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishAudio:) name:kHeyzapDidFinishAudio object:nil];
        // Incentivized
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompleteIncentivizedAd:) name:kHeyzapDidCompleteIncentivizedAd object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToCompleteIncentivizedAd:) name:kHeyzapDidFailToCompleteIncentivizedAd object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Ad Notifications

- (HZAuctionType)auctionType {
    @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"This method is abstract; implement in a subclass" userInfo:nil];
}

- (BOOL)correctAuctionType:(NSNotification *)notification {
    HZAdInfo *info = notification.object;
    NSAssert(info, @"info must not be nil");
    return info.auctionType == [self auctionType];
}

- (void)didFailToShowAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterDidDismissAd:self];
    }
}

- (void)didReceiveAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        HZAdInfo *info = notification.object;
        HZAdType type = hzAdTypeFromString(info.adUnit);
        
        switch (type) {
            case HZAdTypeInterstitial: {
                self.lastInterstitialError = nil;
                break;
            }
            case HZAdTypeIncentivized: {
                self.lastIncentivizedError = nil;
                break;
            }
            case HZAdTypeVideo: {
                self.lastVideoError = nil;
                break;
            }
        }
    }
}
- (void)didFailToReceiveAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        HZAdInfo *info = notification.object;
        HZAdType type = hzAdTypeFromString(info.adUnit);
        
        switch (type) {
            case HZAdTypeInterstitial: {
                self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil];
                break;
            }
            case HZAdTypeIncentivized: {
                self.lastIncentivizedError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil];
                break;
            }
            case HZAdTypeVideo: {
                self.lastVideoError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil];
                break;
            }
        }
    }
}
- (void)didClickAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterWasClicked:self];
    }
}
- (void)didHideAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterDidDismissAd:self];
    }
}

#pragma mark - Audio Notifications
- (void)willStartAudio:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterWillPlayAudio:self];
    }
}

- (void)didFinishAudio:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterDidFinishPlayingAudio:self];
    }
}

#pragma mark - Incentivized Notifications
- (void)didCompleteIncentivizedAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterDidCompleteIncentivizedAd:self];
    }
}
- (void)didFailToCompleteIncentivizedAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
    }
}


@end
