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
    HZVersionCheck()

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

+ (void)showForTag:(NSString *)tag {
    HZShowOptions *options = [HZShowOptions new];
    options.tag = tag;

    [self showWithOptions:options];
}

+ (void)showWithOptions:(HZShowOptions *)options {
    HZVersionCheck()

    if (!options) {
        options = [HZShowOptions new];
    }

    options.tag = options.tag ?: [HeyzapAds defaultTagName];

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapIncentivizedAd showForAuctionType:HZAuctionTypeMixed options:options];
    } else {
        [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeIncentivized additionalParams:nil options:options];
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
    HZVersionCheck()

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapIncentivizedAd fetchForTag: tag auctionType:HZAuctionTypeMixed completion:completion];
    } else {
        [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeIncentivized
                                                     tag:tag
                                        additionalParams:nil
                                              completion:completion];
    }
    
}

#pragma mark - Querying Status

+ (BOOL) isAvailable {
    return [[self class] isAvailableForTag:[HeyzapAds defaultTagName]];
}

+ (BOOL)isAvailableForTag:(NSString *)tag
{
    HZVersionCheckBool()

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        return [HZHeyzapIncentivizedAd isAvailableForTag:tag auctionType:HZAuctionTypeMixed];
    } else {
        return [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:HZAdTypeIncentivized tag:tag];
    }
}

#pragma mark - Heyzap specific

+ (void) setUserIdentifier: (NSString *) userIdentifier {
    HZVersionCheck()

    [HZHeyzapIncentivizedAd setUserIdentifier:userIdentifier];
}

+ (void) setCreativeID:(int)creativeID {
    HZVersionCheck()

    [HZHeyzapIncentivizedAd setCreativeID:creativeID];
}

#pragma mark - Bookkeeping

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZIncentivizedAd' is a static class and cannot be instantiated."];
    return nil;
}


@end
