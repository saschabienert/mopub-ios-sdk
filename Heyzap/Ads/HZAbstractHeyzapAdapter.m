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
#import "HeyzapAds.h"

@interface HZAbstractHeyzapAdapter()

@end

@implementation HZAbstractHeyzapAdapter

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable
{
    return YES;
}

+ (BOOL)isHeyzapAdapter {
    return YES;
}

- (NSError *)initializeSDK {
    return nil;
}

+ (NSString *)sdkVersion {
    return SDK_VERSION;
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeStatic | HZCreativeTypeVideo | HZCreativeTypeIncentivized;
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    if(![self supportsCreativeType:creativeType]) return;
    
    const HZAuctionType auctionType = [self auctionType];
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            // TODO: refactor heyzap network to respect creativeTypes. right now the below call will show videos and statics.
            [HZHeyzapInterstitialAd fetchForAuctionType:auctionType withCompletion:nil];
            break;
        }
        case HZCreativeTypeIncentivized: {
            [HZHeyzapIncentivizedAd fetchForAuctionType:auctionType completion:nil];
            break;
        }
        case HZCreativeTypeVideo: {
            [HZHeyzapVideoAd fetchForAuctionType:auctionType withCompletion:nil];
            break;
        }
        default: {
            // Ignored; Heyzap doesn't support banners, etc.
            break;
        }
    }
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    if(![self supportsCreativeType:creativeType]) return NO;
    
    const HZAuctionType auctionType = [self auctionType];
    if (creativeType & HZCreativeTypeVideo) {
        return [HZHeyzapVideoAd isAvailableForTag:nil auctionType:auctionType];
    } else if (creativeType & HZCreativeTypeStatic) {
        return [HZHeyzapInterstitialAd isAvailableForTag:nil auctionType:auctionType];
    } else if (creativeType & HZCreativeTypeIncentivized) {
        return [HZHeyzapIncentivizedAd isAvailableForTag:nil auctionType:auctionType];
    } else {
        return NO;
    }
}

- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    if(![self supportsCreativeType:creativeType]) return;
    
    // mediation has already called the completion block, so copy the options, excluding the block
    HZShowOptions *newOptions = [options copy];

    const HZAuctionType auctionType = [self auctionType];
    switch (creativeType) {
        case HZCreativeTypeStatic: {
            [HZHeyzapInterstitialAd showForAuctionType:auctionType options:newOptions];
            break;
        }
        case HZCreativeTypeIncentivized: {
            [HZHeyzapIncentivizedAd showForAuctionType:auctionType options:newOptions];
            break;
        }
        case HZCreativeTypeVideo: {
            [HZHeyzapVideoAd showForAuctionType:auctionType options:newOptions];
            break;
        }
        default: {
            // Ignored; Heyzap doesn't support banners, etc.
            break;
        }
    }
}

#pragma mark - NSNotificationCenter registering

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter  defaultCenter] addObserver:self selector:@selector(didShowAd:) name:kHeyzapDidShowAdNotitification object:nil];
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
    HZAssert(info, @"info must not be nil");
    return info.auctionType == [self auctionType];
}

- (void)didShowAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        [self.delegate adapterDidShowAd:self];
    }
}

- (void)didFailToShowAd:(NSNotification *)notification {
    // This is handled automatically by the HeyzapMediation timeout.
    // Potentially it's a worthwhile optimization to tell that to HeyzapMediation directly when possible, to avoid the 1.5s timeout.
}

- (void)didReceiveAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        HZAdInfo *info = notification.object;
        HZAdType type = hzAdTypeFromString(info.adUnit);
        
        switch (type) {
            case HZAdTypeInterstitial: {
                self.lastStaticError = nil;
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
            case HZAdTypeBanner: {
                // Ignored
                break;
            }
        }
        
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackAvailable forNetwork: [self name]];
    }
}
- (void)didFailToReceiveAd:(NSNotification *)notification {
    if ([self correctAuctionType:notification]) {
        HZAdInfo *info = notification.object;
        HZAdType type = hzAdTypeFromString(info.adUnit);
        
        switch (type) {
            case HZAdTypeInterstitial: {
                self.lastStaticError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil];
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
            case HZAdTypeBanner: {
                // Ignored
                break;
            }
        }
        
        [[HeyzapMediation sharedInstance] sendNetworkCallback: HZNetworkCallbackFetchFailed forNetwork: [self name]];
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
