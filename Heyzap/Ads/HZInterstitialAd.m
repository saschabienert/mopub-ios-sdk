//
//  HZInterstitialAd.m
//  Heyzap
//
//  Created by Daniel Rhodes on 5/31/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZInterstitialAd.h"
#import "HZAdsManager.h"
#import "HZAdInterstitialViewController.h"
#import "HZAdVideoViewController.h"
#import "HZAdLibrary.h"
#import "HZAdFetchRequest.h"
#import "HZAdsFetchManager.h"

#import "HZHeyzapInterstitialAd.h"
#import "HeyzapMediation.h"

@implementation HZInterstitialAd

+ (void) setDelegate: (id<HZAdsDelegate>) delegate {
    HZVersionCheck()

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapInterstitialAd setDelegate:delegate];
    } else {
        [[HeyzapMediation sharedInstance] setDelegate:delegate forAdType:HZAdTypeInterstitial];
    }
}

#pragma mark - Showing Ads

+ (void) show {
    [self showForTag:nil];
}

+ (void) showForTag:(NSString *)tag {
    [self showForTag:tag completion:nil];
}

+ (void) showWithViewController:(UIViewController *)vc {
    [self showForTag:nil withViewController:vc];
}

+ (void) showForTag:(NSString *)tag withViewController:(UIViewController *)vc {
    [self showForTag:tag withViewController:vc completion:nil];
}

+ (void)showForTag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion {
    [self showForTag:tag withViewController:nil completion:completion];
}

+ (void)showForTag:(NSString *)tag withViewController:(UIViewController *)vc completion:(void (^)(BOOL result, NSError *error))completion {
    HZVersionCheck()

    tag = tag ?: [HeyzapAds defaultTagName];
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapInterstitialAd showForTag:tag auctionType:HZAuctionTypeMixed completion:completion];
    } else {
        [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeInterstitial tag:tag additionalParams:nil completion:completion];
    }
}

#pragma mark - Fetching Ads

+ (void) fetch {
    [self fetchForTag:nil];
}

+ (void) fetchForTag: (NSString *) tag {
    [self fetchForTag:tag withCompletion:nil];
}

+ (void) fetchWithCompletion: (void (^)(BOOL result, NSError *error))completion {
    [self fetchForTag:nil withCompletion:completion];
}

+ (void) fetchForTag:(NSString *)tag withCompletion: (void (^)(BOOL result, NSError *error))completion {
    HZVersionCheck()

    tag = tag ?: [HeyzapAds defaultTagName];
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapInterstitialAd fetchForTag:tag auctionType:HZAuctionTypeMixed withCompletion:completion];
    } else {
        [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeInterstitial tag:tag additionalParams:nil completion:completion];
    }
}

+ (BOOL) isAvailable {
    return [self isAvailableForTag:nil];
}

+ (BOOL) isAvailableForTag: (NSString *) tag {
    HZVersionCheckBool()

    tag = tag ?: [HeyzapAds defaultTagName];
    
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        return [HZHeyzapInterstitialAd isAvailableForTag:tag auctionType:HZAuctionTypeMixed];
    } else {
        return [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:HZAdTypeInterstitial tag:tag];
    }
}

#pragma mark - Private API

+ (void) setCreativeID:(int)creativeID {
    HZVersionCheck()

    [HZHeyzapInterstitialAd setCreativeID:creativeID];
}

+ (void)forceTestCreative:(BOOL)forceTestCreative
{
    HZVersionCheck()

    [HZHeyzapInterstitialAd forceTestCreative:forceTestCreative];
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZInterstitialAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
