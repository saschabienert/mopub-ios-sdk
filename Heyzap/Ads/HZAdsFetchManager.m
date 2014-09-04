//
//  HZAdsFetchManager.m
//  Heyzap
//
//  Created by Daniel Rhodes on 1/6/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdsFetchManager.h"
#import <UIKit/UIKit.h>
#import "HZAdLibrary.h"
#import "HZAdModel.h"
#import "HeyzapAds.h"
#import "HZAdsAPIClient.h"
#import "HZAdsManager.h"
#import "HZAdFetchRequest.h"
#import "HZAdsAPIClient.h"
#import "HZDevice.h"
#import "HZMetrics.h"

@implementation HZAdsFetchManager

- (void) fetch: (HZAdFetchRequest *) request withCompletion:(void (^)(HZAdModel *, NSString *, NSError *))completion {
    // Already have the ad, let's bail out.
    HZAdModel *ad = [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit:request.adUnit tag:request.tag auctionType:request.auctionType];
    if (ad != nil && !request.shouldSkipCache) {
        // ad is available. no need to fetch another.
        if (![ad isExpired]) return;
        
        // ad is expired. purge it and continue.
        [[HZAdLibrary sharedLibrary] purgeAd: ad];
    }
    
    const CFTimeInterval startTime = CACurrentMediaTime();
    [[HZMetrics sharedInstance] logMetricsEvent:kFetchKey value:@1 tag:request.tag type:request.adUnit];
    [[HZMetrics sharedInstance] logFetchTimeForTag:request.tag type:request.adUnit];
    
    NSString *const connectivity = [[HZDevice currentDevice] HZConnectivityType];
    [[HZMetrics sharedInstance] logMetricsEvent:@"connectivity"
                                          value:connectivity
                                            tag:request.tag
                                           type:request.adUnit];
    
    [[HZAdsAPIClient sharedClient] loadRequest: request withCompletion: ^(HZAdFetchRequest *aRequest) {
        const CFTimeInterval elapsedSeconds = CACurrentMediaTime() - startTime;
        const int64_t elapsedMiliseconds = lround(elapsedSeconds*1000);
        [[HZMetrics sharedInstance] logMetricsEvent:@"fetch_download_time" value:@(elapsedMiliseconds) tag:aRequest.tag type:aRequest.adUnit];
        
        if (aRequest.lastError != nil) {
            
            [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", aRequest.lastError]];
            [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailedKey value:@1 tag:aRequest.tag type:aRequest.adUnit];
            if (aRequest.lastFailingStatusCode) {
                [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailReasonKey value:@(aRequest.lastFailingStatusCode) tag:request.tag type:request.adUnit];
            } else if (!connectivity) {
                [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailReasonKey value:@"no-connectivity" tag:request.tag type:request.adUnit];
            }
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didFailToReceiveAdWithTag: request.tag];
            
            if (completion) {
                completion(nil, aRequest.tag, aRequest.lastError);
            }
        } else {
            [self handleSuccessWithRequest: aRequest withCompletion: completion];
        }
    }];
}

- (void) handleSuccessWithRequest: (HZAdFetchRequest *) request withCompletion: (void (^)(HZAdModel *, NSString *, NSError *))completion  {
    BOOL validAd = YES;
    HZAdModel *ad;
    
    // Handle invalid ads, errors, and no fills
    NSError *error;
    if (![HZAdModel isResponseValid: request.lastResponse withError: &error]) {
        validAd = NO;
    } else {
        ad = [HZAdModel modelForResponse: request.lastResponse adUnit:request.adUnit];
        if (ad == nil) {
            validAd = NO;
        }
    }
    
    if (!validAd) {
        
        [[[HZAdsManager sharedManager] delegateForAdUnit:request.adUnit] didFailToReceiveAdWithTag:request.tag];
        
        if (completion) {
            NSError *error;
            if ([request.lastResponse objectForKey: @"impression_id"] != nil) {
                error =  [NSError errorWithDomain: @"com.heyzap.sdk.ads.fetch" code: 4 userInfo: @{NSLocalizedDescriptionKey: @"Failed to fetch a valid ad."}];
            } else {
                error =  [NSError errorWithDomain: @"com.heyzap.sdk.ads.fetch" code: 5 userInfo: @{NSLocalizedDescriptionKey: @"No fill."}];
            }

            [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", error]];
            completion(nil, request.tag, error);
        }
        
        return;
    }
    
    ad.tag = request.tag;
    ad.adUnit = request.adUnit;
    
    if ([ad isInstalled] && [request canRetry]) {
        
        [HZLog debug: [NSString stringWithFormat: @"%@ already installed. Trying again.", ad]];
        
        request.alreadyInstalledGame = ad.promotedGamePackage;
        request.rejectedImpressionID = ad.impressionID;
        [request decrementTries];
        [self fetch: request withCompletion: completion];
        
        return;
    } else if ([ad isInstalled] && !request.shouldIgnoreAlreadyInstalledGame) {
        
        if (completion) {
            NSError *error =  [NSError errorWithDomain: @"com.heyzap.sdk.ads.fetch" code: 5 userInfo: @{NSLocalizedDescriptionKey: @"No fill."}];
            [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", error]];
            completion(nil, request.tag, error);
        }
        
        return;
    }
    
    // Set session specific data
    __block HZAdFetchRequest *bRequest = request;
    [ad doPostFetchActionsWithCompletion:^(BOOL result) {
        if (result) {
            
            [HZLog debug: [NSString stringWithFormat: @"(FETCH) %@", ad]];
            
            [[HZAdLibrary sharedLibrary] pushAd:ad forAdUnit:request.adUnit tag:request.tag auctionType:request.auctionType];
            
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didReceiveAdWithTag: request.tag];
            
            if (completion) {
                completion(ad, bRequest.tag, nil);
            }
            
        } else {
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didFailToReceiveAdWithTag: request.tag];
            
            if (completion) {
                NSError *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.fetch" code: 8 userInfo: @{NSLocalizedDescriptionKey: @"Failed to download assets."}];
                [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", error]];
                completion(nil, bRequest.tag, error);
            }
        }
    }];
}

+ (instancetype)sharedManager {
    static HZAdsFetchManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedManager) {
            sharedManager = [[HZAdsFetchManager alloc] init];
        }
    });
    return sharedManager;
}

@end
