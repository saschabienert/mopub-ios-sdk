//
//  HZHeyzapIncentivizedAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/4/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapIncentivizedAd.h"
#import "HZAdViewController.h"
#import "HZAdLibrary.h"
#import "HZAdFetchRequest.h"
#import "HZAdsFetchManager.h"
#import "HZAdsManager.h"

#define HZIncentivizedAdUnit @"incentivized"
#define HZIncentivizedAdCreativeTypes @[@"video", @"interstitial_video"]

static int HZIncentivizedCreativeIDPin = 0;

@implementation HZHeyzapIncentivizedAd

+ (void)showForAuctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options
{
    if (![HZAdsManager isEnabled]) {
        return;
    }
    
    [[HZAdsManager sharedManager] showForAdUnit:HZIncentivizedAdUnit auctionType:auctionType options:options];
}

+ (void)fetchForAuctionType:(HZAuctionType)auctionType completion:(void (^)(BOOL result, NSError *error))completion {
    if ([HZAdsManager isEnabled]) {
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (HZIncentivizedCreativeIDPin > 0) {
            [params setObject: [NSString stringWithFormat: @"%i", HZIncentivizedCreativeIDPin] forKey: @"creative_id"];
        }
        
        HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes: HZIncentivizedAdCreativeTypes adUnit: HZIncentivizedAdUnit tag:nil auctionType:auctionType andAdditionalParams: params];
        
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

+ (void)hide
{
    [[HZAdsManager sharedManager] hideActiveAd];
}

+ (void) setCreativeID:(int)creativeID {
    if (creativeID > 0) {
        HZIncentivizedCreativeIDPin = creativeID;
    } else {
        HZIncentivizedCreativeIDPin = 0;
    }
}

+ (BOOL)isAvailableForTag:(NSString *)tag auctionType:(HZAuctionType)auctionType
{
    if (![HZAdsManager isEnabled]) return NO;
    return [[HZAdsManager sharedManager] isAvailableForAdUnit:HZIncentivizedAdUnit auctionType:auctionType];
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZIncentivizedAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
