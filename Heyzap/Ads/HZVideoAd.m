//
//  HZVideoAd.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZVideoAd.h"
#import "HZMetrics.h"
#import "HZAdsManager.h"
#import "HZAdLibrary.h"
#import "HZAdViewController.h"
#import "HZAdsFetchManager.h"
#import "HZAdFetchRequest.h"
#import "HZAdsAPIClient.h"

#define HZVideoAdUnit @"video"
#define HZVideoAdCreativeTypes @[@"video", @"interstitial_video"]

static int HZVideoAdCreativeIDPin = 0;

@implementation HZVideoAd

+ (void) setDelegate:(id<HZAdsDelegate>)delegate {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] setVideoDelegate: delegate];
    }
}

+ (void) showWithCompletion:(void (^)(BOOL result, NSError *error))completion {
    [self showForTag: nil completion: completion];
}

+ (void)showForTag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion {
    if (![[HZAdsManager sharedManager] isEnabled]) return;
    [[HZAdsManager sharedManager] showForAdUnit: HZVideoAdUnit andTag: tag withCompletion: completion];
}

+ (void) showForTag:(NSString *)tag {
    [self showForTag: tag completion: nil];
}

// -----------

+ (void) show {
    [self showForTag: nil];
}

+ (void) hide {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] hideActiveAd];
    }
}

+ (void) fetch {
    [self fetchForTag: [HeyzapAds defaultTagName] withCompletion: nil];
}

+ (void) fetchForTag: (NSString *) tag {
    [self fetchForTag: tag withCompletion: nil];
}

+ (void) fetchForTag:(NSString *)tag withCompletion: (void (^)(BOOL result, NSError *error))completion {
    NSString *type = @"video";
    if ([[HZAdsManager sharedManager] isEnabled]) {
        
        NSDictionary *params = (HZVideoAdCreativeIDPin > 0) ? @{@"creative_id": [NSString stringWithFormat: @"%i", HZVideoAdCreativeIDPin]} : nil;
        
        HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes: HZVideoAdCreativeTypes
                                                                             adUnit: HZVideoAdUnit
                                                                                tag: tag
                                                                andAdditionalParams: params];
        CFTimeInterval startTime = CACurrentMediaTime();
        [[HZAdsFetchManager sharedManager] fetch: request
                                  withCompletion:^(HZAdModel *ad, NSString *tag, NSError *error) {
            CFTimeInterval elapsedSeconds = CACurrentMediaTime() - startTime;
            int64_t elapsedMiliseconds = lround(elapsedSeconds*1000);
            [[HZMetrics sharedInstance] logMetricsEvent:@"fetch_download_time" value:@(elapsedMiliseconds) tag:tag type:type];
            if (completion) {
                BOOL result = YES;
                if (error != nil || ad == nil) {
                    result = NO;
                    
                } else {
                    [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailedKey value:@1 tag:tag type:type];
                    [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailReasonKey value:error tag:tag type:type];
                }
                completion(result, error);
            }
        }];
    }
}

+ (void) fetchWithCompletion: (void (^)(BOOL result, NSError *error))completion {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [self fetchForTag: [HeyzapAds defaultTagName] withCompletion: completion];
    }
}

+ (BOOL) isAvailable {
    return [self isAvailableForTag: [HeyzapAds defaultTagName]];
}

+ (BOOL) isAvailableForTag: (NSString *) tag {
    if (![[HZAdsManager sharedManager] isEnabled]) return NO;
    
    [[HZMetrics sharedInstance] logMetricsEvent:kIsAvailableCalledKey value:@1 tag:tag type:HZVideoAdUnit];
    [[HZMetrics sharedInstance] logTimeSinceFetchFor:kIsAvailableTimeSincePreviousFetchKey tag:tag type:HZVideoAdUnit];
    [[HZMetrics sharedInstance] logDownloadPercentageFor:kIsAvailablePercentDownloadedKey tag:tag type:HZVideoAdUnit];

    const BOOL available = [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit: HZVideoAdUnit withTag: tag] != nil;
    
    [[HZMetrics sharedInstance] logIsAvailable:available tag:tag type:HZVideoAdUnit];
    
    return available;
}

+ (void) setCreativeID:(int)creativeID {
    if (creativeID > 0) {
        HZVideoAdCreativeIDPin = creativeID;
    } else {
        HZVideoAdCreativeIDPin = 0;
    }
}


+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZVideoAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
