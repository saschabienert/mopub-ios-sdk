//
//  HZHeyzapInterstitialAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapInterstitialAd.h"
#import "HZAdsManager.h"
#import "HZAdInterstitialViewController.h"
#import "HZAdVideoViewController.h"
#import "HZAdLibrary.h"
#import "HZAdFetchRequest.h"
#import "HZAdsFetchManager.h"

#define HZInterstitialAdCreativeTypes @[@"interstitial", @"full_screen_interstitial", @"video", @"interstitial_video"]
#define HZInterstitialAdCreativeTypesNoVideo @[@"interstitial", @"full_screen_interstitial"]
#define HZInterstitialAdUnit @"interstitial"

static int HZInterstitialAdCreativeIDPin = 0;
static BOOL HZInterstitialForceTestCreative = NO;
static NSString *HZInterstitialForcedCreativeType = nil;

@implementation HZHeyzapInterstitialAd

+ (void)showForAuctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options {
    if (![HZAdsManager isEnabled]) {
        return;
    }
    
    [[HZAdsManager sharedManager] showForCreativeType:HZCreativeTypeStatic auctionType:auctionType options:options];
}

+ (void) hide {
    if ([HZAdsManager isEnabled]) {
        [[HZAdsManager sharedManager] hideActiveAd];
    }
}

+ (void) fetchForAuctionType:(HZAuctionType)auctionType withCompletion: (void (^)(BOOL result, NSError *error))completion {
    if ([HZAdsManager isEnabled]) {
        HZAdFetchRequest *request = [self requestWithAuctionType:auctionType];
        [[HZAdsFetchManager sharedManager] fetch: request withCompletion:^(HZAdModel *ad, NSError *error) {
            if (completion) {
                BOOL result = YES;
                if (error != nil || ad == nil) {
                    result = NO;
                }
                completion(result, error);
            }
        }];
    }
}

+ (BOOL) isAvailableForTag:(NSString *)tag auctionType:(HZAuctionType)auctionType {
    if (![HZAdsManager isEnabled]) return NO;
    return [[HZAdsManager sharedManager] isAvailableForFetchableCreativeType:HZFetchableCreativeTypeStatic auctionType:auctionType];
}

+ (void) setCreativeID:(int)creativeID {
    if (creativeID > 0) {
        HZInterstitialAdCreativeIDPin = creativeID;
    } else {
        HZInterstitialAdCreativeIDPin = 0;
    }
}

+ (void)forceTestCreative:(BOOL)forceTestCreative
{
    HZInterstitialForceTestCreative = forceTestCreative;
}

+ (void)setCreativeType:(NSString *)creativeType {
    HZInterstitialForcedCreativeType = creativeType;
}

+ (HZAdFetchRequest *) requestWithAuctionType:(HZAuctionType)auctionType {
    NSDictionary *params = nil;
    
    if (HZInterstitialForceTestCreative) {
        params = @{@"force_test_creative":@"true"};
    } else if (HZInterstitialAdCreativeIDPin > 0) {
        params = @{@"creative_id": [NSString stringWithFormat: @"%i", HZInterstitialAdCreativeIDPin]};
    } else if (HZInterstitialForcedCreativeType) {
        params = @{@"forced_creative_type":HZInterstitialForcedCreativeType};
    }
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithFetchableCreativeType:HZFetchableCreativeTypeStatic
                                                                                    tag:nil
                                                                            auctionType:auctionType
                                                                    andAdditionalParams:params];
    
    return request;
}

#pragma mark - Private API

+ (void)showAdWithOptions:(NSDictionary *)options
{
    HZParameterAssert(options);
    if ([HZAdsManager isEnabled]) {
        
    }
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZInterstitialAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
