//
//  HZIncentivizedAd.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZMetrics.h"
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
    [[self class] showForTag:[HeyzapAds defaultTagName]];
}

+ (void)showForTag:(NSString *)tag
{
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapIncentivizedAd showForTag:tag];
    } else {
        [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeIncentivized tag:tag completion:nil];
    }
}

#pragma mark - Fetching Ads

+ (void) fetch {
    [self fetchForTag: [HeyzapAds defaultTagName] withCompletion: nil];
}

+ (void)fetchForTag:(NSString *)tag {
    [[self class] fetchForTag:tag withCompletion:nil];
}

+ (void) fetchWithCompletion:(void (^)(BOOL, NSError *))completion {
    [[self class] fetchForTag:[HeyzapAds defaultTagName] withCompletion:completion];
}

+ (void) fetchForTag: (NSString *) tag withCompletion:(void (^)(BOOL, NSError *))completion
{
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapIncentivizedAd fetchWithCompletion:completion];
    } else {
        [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeIncentivized
                                                     tag:[HeyzapAds defaultTagName]
                                              completion:completion];
    }
    
}

#pragma mark - Querying Status

+ (BOOL) isAvailable {
    return [[self class] isAvailableForTag:[HeyzapAds defaultTagName]];
}

+ (BOOL)isAvailableForTag:(NSString *)tag
{
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        return [HZHeyzapIncentivizedAd isAvailableForTag:tag];
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
