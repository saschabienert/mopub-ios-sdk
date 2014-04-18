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
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapVideoAd setDelegate:delegate];
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
    
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapVideoAd showForTag:tag completion:completion];
    } else {
        [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeVideo tag:tag completion:completion];
    }
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
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZHeyzapVideoAd fetchForTag:tag withCompletion:completion];
    } else {
        [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeVideo tag:tag completion:completion];
    }
}

#pragma mark - Querying

+ (BOOL) isAvailable {
    return [self isAvailableForTag:nil];
}

+ (BOOL) isAvailableForTag: (NSString *) tag {
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        return [HZHeyzapVideoAd isAvailableForTag:tag];
    } else {
        return [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:HZAdTypeVideo tag:tag];
    }
}

#pragma mark - Heyzap Only

+ (void) setCreativeID:(int)creativeID {
    [HZHeyzapVideoAd setCreativeID:creativeID];
}

#pragma mark - Bookkeeping

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZVideoAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
