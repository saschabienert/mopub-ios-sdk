//
//  HZIncentivizedAd.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdsManager.h"
#import "HZAdViewController.h"
#import "HZAdLibrary.h"
#import "HZAdFetchRequest.h"
#import "HZAdsFetchManager.h"

#define HZIncentivizedAdUnit @"incentivized"
#define HZIncentivizedAdCreativeTypes @[@"video", @"interstitial_video"]

#import "HZIncentivizedAd.h"
#import "HeyzapMediation.h"
#import "HZHeyzapIncentivizedAd.h"

@implementation HZIncentivizedAd

#pragma mark - Delegation

+ (void)setDelegate:(id<HZIncentivizedAdDelegate>)delegate
{
    if ([HeyzapMediation isOnlyHeyzapSDK]){
        [HZHeyzapIncentivizedAd setDelegate:delegate];
    } else {
        [[HeyzapMediation sharedInstance] setDelegate:delegate forAdType:HZAdTypeIncentivized];
    }
}

#pragma mark - Showing Ads

+ (void) show {
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapIncentivizedAd show];
    } else {
        [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeIncentivized tag:[HeyzapAds defaultTagName] completion:nil];
    }
}

#pragma mark - Fetching Ads

+ (void) fetch {
    [self fetchForTag: [HeyzapAds defaultTagName] withCompletion: nil];
}

+ (void) fetchWithCompletion:(void (^)(BOOL, NSError *))completion {
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapIncentivizedAd fetchWithCompletion:completion];
    } else {
        [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeIncentivized
                                                     tag:[HeyzapAds defaultTagName]
                                              completion:completion];
    }
}

+ (BOOL) isAvailable {
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        return [HZHeyzapIncentivizedAd isAvailable];
    } else {
        return [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:HZAdTypeIncentivized tag:[HeyzapAds defaultTagName]];
    }
}

#pragma mark - Heyzap specific

+ (void) setUserIdentifier: (NSString *) userIdentifier {
    [HZHeyzapIncentivizedAd setUserIdentifier:userIdentifier];
}

+ (void) setCreativeID:(int)creativeID {
    [HZHeyzapIncentivizedAd setCreativeID:creativeID];
}

#pragma mark - Bookkeeping

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZIncentivizedAd' is a static class and cannot be instantiated."];
    return nil;
}


@end
