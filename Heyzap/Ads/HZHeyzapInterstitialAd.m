//
//  HZHeyzapInterstitialAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapInterstitialAd.h"
#import "HZAnalytics.h"
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

@implementation HZHeyzapInterstitialAd

+ (void) setDelegate: (id<HZAdsDelegate>) delegate {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] setInterstitialDelegate:delegate];
    }
}

+ (void)showForTag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion {
    
    if (![[HZAdsManager sharedManager] isEnabled]) {
        return;
    }
    
    if (tag == nil) {
        tag = [HeyzapAds defaultTagName];
    }
    
    if (![self isAvailableForTag: tag]) {
        HZAdFetchRequest *request = [self requestWithTag: tag andVideo: NO];
        [[HZAdsFetchManager sharedManager] fetch: request withCompletion:^(HZAdModel *ad, NSString *tag, NSError *error) {
            [[HZAdsManager sharedManager] showForAdUnit: HZInterstitialAdUnit andTag: tag withCompletion: completion];
        }];
    } else {
        [[HZAdsManager sharedManager] showForAdUnit: HZInterstitialAdUnit andTag: tag withCompletion: completion];
    }
}

+ (void) hide {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] hideActiveAd];
    }
}

+ (void) fetchForTag:(NSString *)tag withCompletion: (void (^)(BOOL result, NSError *error))completion {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        
        HZAdFetchRequest *request = [self requestWithTag: tag andVideo: YES];
        
        [[HZAdsFetchManager sharedManager] fetch: request withCompletion:^(HZAdModel *ad, NSString *tag, NSError *error) {
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

+ (BOOL) isAvailableForTag: (NSString *) tag {
    if (![[HZAdsManager sharedManager] isEnabled]) return NO;
    
    return [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit: HZInterstitialAdUnit withTag: tag] != nil;
}

+ (void) setCreativeID:(int)creativeID {
    if (creativeID > 0) {
        HZInterstitialAdCreativeIDPin = creativeID;
    } else {
        HZInterstitialAdCreativeIDPin = 0;
    }
}

+ (HZAdFetchRequest *) requestWithTag: (NSString *) tag andVideo: (BOOL) withVideo {
    NSDictionary *params = nil;
    
    if (HZInterstitialAdCreativeIDPin > 0) {
        params = @{@"creative_id": [NSString stringWithFormat: @"%i", HZInterstitialAdCreativeIDPin]};
    }
    
    NSArray *creativeTypes = withVideo ? HZInterstitialAdCreativeTypes : HZInterstitialAdCreativeTypesNoVideo;
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes: creativeTypes adUnit: HZInterstitialAdUnit tag: tag andAdditionalParams: params];
    
    return request;
}

#pragma mark - Private API

+ (void)showAdWithOptions:(NSDictionary *)options
{
    NSParameterAssert(options);
    if ([[HZAdsManager sharedManager] isEnabled]) {
        
    }
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZInterstitialAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
