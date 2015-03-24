//
//  HZVideoAd.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZVideoAd.h"
#import "HZAdsManager.h"
#import "HZAdLibrary.h"
#import "HZAdViewController.h"
#import "HZAdsFetchManager.h"
#import "HZAdFetchRequest.h"
#import "HZAdsAPIClient.h"
#import "HeyzapMediation.h"
#import "HZHeyzapVideoAd.h"

@implementation HZVideoAd

#pragma mark - Delegation

+ (void)setDelegate:(id<HZAdsDelegate>)delegate
{
    HZVersionCheck()

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [[HZAdsManager sharedManager] setVideoDelegate: delegate];
    } else {
        [[HeyzapMediation sharedInstance] setDelegate:delegate forAdType:HZAdTypeVideo];
    }
}

#pragma mark - Showing

+ (void) show {
    [self showForTag: nil];
}

+ (void) showForTag:(NSString *)tag {
    [self showForTag: tag completion: nil];
}

+ (void)showForTag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion {
    HZShowOptions *options = [HZShowOptions new];
    options.tag = tag;
    options.completion = completion;

    [self showWithOptions:options];
}

+ (void) showWithOptions:(HZShowOptions *)options {
    HZVersionCheck()

    if (!options) {
        options = [HZShowOptions new];
    }

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapVideoAd showForAuctionType:HZAuctionTypeMixed options:options];
    } else {
        [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeVideo additionalParams:nil options:options];
    }
}

+ (void) showWithCompletion:(void (^)(BOOL result, NSError *error))completion {
    [self showForTag: nil completion: completion];
}

#pragma mark - Fetching


+ (void) fetch {
    [self fetchForTag:nil withCompletion: nil];
}

+ (void) fetchForTag: (NSString *) tag {
    [self fetchForTag: tag withCompletion: nil];
}

+ (void) fetchWithCompletion: (void (^)(BOOL result, NSError *error))completion {
    [self fetchForTag:nil withCompletion:completion];
}

+ (void) fetchForTag:(NSString *)tag withCompletion: (void (^)(BOOL result, NSError *error))completion {
    HZVersionCheck()

    tag = tag ?: [HeyzapAds defaultTagName];

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapVideoAd fetchForTag:tag auctionType:HZAuctionTypeMixed withCompletion:completion];
    } else {
        [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeVideo tag:tag additionalParams:nil completion:completion];
    }
}

#pragma mark - Querying

+ (BOOL) isAvailable {
    return [self isAvailableForTag:nil];
}

+ (BOOL) isAvailableForTag: (NSString *) tag {
    HZVersionCheckBool()

    tag = tag ?: [HeyzapAds defaultTagName];

    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        return [HZHeyzapVideoAd isAvailableForTag:tag auctionType:HZAuctionTypeMixed];
    } else {
        return [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:HZAdTypeVideo tag:tag];
    }
}

#pragma mark - Heyzap Only

+ (void) setCreativeID:(int)creativeID {
    HZVersionCheck()

    [HZHeyzapVideoAd setCreativeID:creativeID];
}

#pragma mark - Bookkeeping

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZVideoAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
