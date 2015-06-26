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
#import "HZEnums.h"
#import "HZUtils.h"

@implementation HZAdsFetchManager

- (void) fetch: (HZAdFetchRequest *) request withCompletion:(void (^)(HZAdModel *, NSError *))completion {
    // Already have the ad, let's bail out.
    HZAdModel *ad = [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit:request.adUnit auctionType:request.auctionType];
    if (ad != nil && !request.shouldSkipCache) {
        // ad is available. no need to fetch another.
        if (![ad isExpired]) return;
        
        // ad is expired. purge it and continue.
        [[HZAdLibrary sharedLibrary] purgeAd: ad];
    }
    
    [[HZAdsAPIClient sharedClient] loadRequest: request withCompletion: ^(HZAdFetchRequest *aRequest) {
        
        if (aRequest.lastError != nil) {
            
            [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", aRequest.lastError]];
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didFailToReceiveAdWithTag: nil];
            [HZAdsManager postNotificationName:kHeyzapDidFailToReceiveAdNotification infoProvider:request];
            
            if (completion) {
                completion(nil, aRequest.lastError);
            }
        } else {
            [self handleSuccessWithRequest: aRequest withCompletion: completion];
        }
    }];
}

- (void) handleSuccessWithRequest: (HZAdFetchRequest *) request withCompletion: (void (^)(HZAdModel *, NSError *))completion  {
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
        [[[HZAdsManager sharedManager] delegateForAdUnit:request.adUnit] didFailToReceiveAdWithTag:nil];
        [HZAdsManager postNotificationName:kHeyzapDidFailToReceiveAdNotification infoProvider:request];
        
        if (completion) {
            NSError *error;
            if ([request.lastResponse objectForKey: @"impression_id"] != nil) {
                error =  [NSError errorWithDomain: @"com.heyzap.sdk.ads.fetch" code: 4 userInfo: @{NSLocalizedDescriptionKey: @"Failed to fetch a valid ad."}];
            } else {
                error =  [NSError errorWithDomain: @"com.heyzap.sdk.ads.fetch" code: 5 userInfo: @{NSLocalizedDescriptionKey: @"No fill."}];
            }

            [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", error]];
            completion(nil, error);
        }
        
        return;
    }
    
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
            completion(nil, error);
        }
        
        return;
    }
    
    // Set session specific data
    [ad doPostFetchActionsWithCompletion:^(BOOL result) {
        if (result) {
            
            [[HZAdLibrary sharedLibrary] pushAd:ad forAdUnit:request.adUnit auctionType:request.auctionType];
            
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didReceiveAdWithTag:nil];
            [HZAdsManager postNotificationName:kHeyzapDidReceiveAdNotification infoProvider:request];
            
            if (completion) {
                completion(ad, nil);
            }
            
        } else {
            [[[HZAdsManager sharedManager] delegateForAdUnit: request.adUnit] didFailToReceiveAdWithTag: nil];
            [HZAdsManager postNotificationName:kHeyzapDidFailToReceiveAdNotification infoProvider:request];
            
            if (completion) {
                NSError *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.fetch" code: 8 userInfo: @{NSLocalizedDescriptionKey: @"Failed to download assets."}];
                [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", error]];
                completion(nil, error);
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
