//
//  HZInterstitialAd.m
//  Heyzap
//
//  Created by Daniel Rhodes on 5/31/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZInterstitialAd.h"
#import "HZMetrics.h"
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

@implementation HZInterstitialAd

+ (void) setDelegate: (id<HZAdsDelegate>) delegate {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] setInterstitialDelegate: delegate];
    }
}

+ (void) showWithCompletion:(void (^)(BOOL result, NSError *error))completion {
    [self showForTag: nil completion: completion];
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

+ (void) showForTag:(NSString *)tag {
    [HZInterstitialAd showForTag: tag completion: nil];
}

// Backwards Compatibility.
+ (void) showWithTag: (NSString *) tag {
    [self showForTag: tag];
}

+ (void)showWithTag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion {
    [self showForTag: tag completion: completion];
}
// -----------

+ (void) show {
    [HZInterstitialAd showForTag: nil];
}

+ (void) hide {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] hideActiveAd];
    }
}

+ (void) fetch {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [HZInterstitialAd fetchForTag: [HeyzapAds defaultTagName]];
    }
}

+ (void) fetchForTag: (NSString *) tag {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [HZInterstitialAd fetchForTag: tag withCompletion: nil];
    }
}

+ (void) fetchForTag:(NSString *)tag withCompletion: (void (^)(BOOL result, NSError *error))completion {
    if ([[HZAdsManager sharedManager] isEnabled]) {
[       [HZMetrics sharedInstance] logFetchTimeForTag:tag andType:HZInterstitialAdUnit];
        
        HZAdFetchRequest *request = [self requestWithTag: tag andVideo: YES];
        CFTimeInterval startTime = CACurrentMediaTime();
        [[HZAdsFetchManager sharedManager] fetch: request withCompletion:^(HZAdModel *ad, NSString *tag, NSError *error) {
            CFTimeInterval elapsedSeconds = CACurrentMediaTime() - startTime;
            int64_t elapsedMiliseconds = lround(elapsedSeconds*1000);
            [[HZMetrics sharedInstance] logMetricsEvent:@"fetch-download-time" withValue:@(elapsedMiliseconds) forTag:tag andType:HZInterstitialAdUnit];
            if (completion) {
                BOOL result = YES;
                if (error != nil || ad == nil) {
                    result = NO;
                    [[HZMetrics sharedInstance] logMetricsEvent:@"fetch" withValue:@0 forTag:tag andType:HZInterstitialAdUnit];
                } else {
                    [[HZMetrics sharedInstance] logMetricsEvent:@"fetch-fail" withValue:@1 forTag:tag andType:HZInterstitialAdUnit];
                    [[HZMetrics sharedInstance] logMetricsEvent:@"fetch-fail-reason" withValue:error forTag:tag andType:HZInterstitialAdUnit];
                }
                
                completion(result, error);
            }
        }];
    }
}

+ (void) fetchWithCompletion: (void (^)(BOOL result, NSError *error))completion {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [HZInterstitialAd fetchForTag: [HeyzapAds defaultTagName] withCompletion: completion];
    }
}

+ (BOOL) isAvailable {
    return [self isAvailableForTag: [HeyzapAds defaultTagName]];
}

+ (BOOL) isAvailableForTag: (NSString *) tag {
    if (![[HZAdsManager sharedManager] isEnabled]) return NO;
    [[HZMetrics sharedInstance] logMetricsEvent:@"is-availible" withValue:@1 forTag:tag andType:HZInterstitialAdUnit];
    [[HZMetrics sharedInstance] logTimeSinceFetchFor:@"is-availible-time-since-fetch" forTag:tag andType:HZInterstitialAdUnit];
    [[HZMetrics sharedInstance] logDownloadPercentageFor:@"is-availible-download" forTag:tag andType:HZInterstitialAdUnit];
    
    BOOL available = [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit: HZInterstitialAdUnit withTag: tag] != nil;
    
    if (available){
        [[HZMetrics sharedInstance] logMetricsEvent:@"is-availible-result" withValue:@"is-availible" forTag:tag andType:HZInterstitialAdUnit];
    } else {
        [[HZMetrics sharedInstance] logMetricsEvent:@"is-availible-result" withValue:@"is-not-availible" forTag:tag andType:HZInterstitialAdUnit];
    }

    return available;
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
