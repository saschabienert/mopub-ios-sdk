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
#import "HZEnums.h"
#import "HZUtils.h"

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
    NSString *heyzapAdapter = HeyzapAdapterFromHZAuctionType(request.auctionType);
    [[HZMetrics sharedInstance] logMetricsEvent:kNetworkKey value:heyzapAdapter withProvider:request network:heyzapAdapter];
    [[HZMetrics sharedInstance] logMetricsEvent:kOrdinalKey value:@0 withProvider:request network:heyzapAdapter];
    [[HZMetrics sharedInstance] logMetricsEvent:kAdUnitKey value:request.adUnit withProvider:request network:heyzapAdapter];
    [[HZMetrics sharedInstance] logMetricsEvent:kFetchKey value:@1 withProvider:request network:heyzapAdapter];
    [[HZMetrics sharedInstance] logFetchTimeWithObject:request network:heyzapAdapter];
    
    NSString *const connectivity = [HZUtils internetStatus];
    [[HZMetrics sharedInstance] logMetricsEvent:kConnectivityKey
                                          value:connectivity
                                     withProvider:request
                                        network:heyzapAdapter];
    
    [[HZAdsAPIClient sharedClient] loadRequest: request withCompletion: ^(HZAdFetchRequest *aRequest) {
        const int64_t elapsedMiliseconds = millisecondsSinceCFTimeInterval(startTime);
        [[HZMetrics sharedInstance] logMetricsEvent:kFetchDownloadTimeKey value:@(elapsedMiliseconds) withProvider:aRequest network:heyzapAdapter];
        
        if (aRequest.lastError != nil) {
            
            [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", aRequest.lastError]];
            [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailedKey value:@1 withProvider:aRequest network:heyzapAdapter];
            if (aRequest.lastFailingStatusCode) {
                [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailReasonKey value:@(aRequest.lastFailingStatusCode) withProvider:aRequest network:heyzapAdapter];
            } else if ([connectivity isEqualToString:@"no_internet"]) {
                [[HZMetrics sharedInstance] logMetricsEvent:kFetchFailReasonKey value:kNoConnectivityValue withProvider:aRequest network:heyzapAdapter];
            }
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didFailToReceiveAdWithTag: request.tag];
            [HZAdsManager postNotificationName:kHeyzapDidFailToReceiveAdNotification infoProvider:request];
            
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
        ad = [HZAdModel modelForResponse: request.lastResponse adUnit:request.adUnit auctionType:request.auctionType];
        if (ad == nil) {
            validAd = NO;
        }
    }
    
    if (!validAd) {
        
        [[[HZAdsManager sharedManager] delegateForAdUnit:request.adUnit] didFailToReceiveAdWithTag:request.tag];
        [HZAdsManager postNotificationName:kHeyzapDidFailToReceiveAdNotification infoProvider:request];
        
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
            [HZAdsManager postNotificationName:kHeyzapDidReceiveAdNotification infoProvider:request];
            
            if (completion) {
                completion(ad, bRequest.tag, nil);
            }
            
        } else {
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didFailToReceiveAdWithTag: request.tag];
            [HZAdsManager postNotificationName:kHeyzapDidFailToReceiveAdNotification infoProvider:request];
            
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
