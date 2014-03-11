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

@implementation HZAdsFetchManager

- (void) fetch: (HZAdFetchRequest *) request withCompletion:(void (^)(HZAdModel *, NSString *, NSError *))completion {
    // Already have the ad, let's bail out.
    HZAdModel *ad = [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit: request.adUnit withTag: request.tag];
    if (ad != nil && !request.shouldSkipCache) {
        // ad is available. no need to fetch another.
        if (![ad isExpired]) return;
        
        // ad is expired. purge it and continue.
        [[HZAdLibrary sharedLibrary] purgeAd: ad];
    }
    
    [[HZAdsAPIClient sharedClient] loadRequest: request withCompletion: ^(HZAdFetchRequest *aRequest) {
        if (aRequest.lastError != nil) {
            
            [HZLog debug: [NSString stringWithFormat: @"(FETCH) Error: %@", aRequest.lastError]];
            
            if ([[HZAdsManager sharedManager].statusDelegate respondsToSelector:@selector(didFailToReceiveAdWithTag:)]) {
                [[HZAdsManager sharedManager].statusDelegate didFailToReceiveAdWithTag:request.tag];
            }
            
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
        ad = [HZAdModel modelForResponse: request.lastResponse];
        if (ad == nil) {
            validAd = NO;
        }
    }
    
    if (!validAd) {
        
        if ([[HZAdsManager sharedManager].statusDelegate respondsToSelector:@selector(didFailToReceiveAdWithTag:)]) {
            [[HZAdsManager sharedManager].statusDelegate didFailToReceiveAdWithTag:request.tag];
        }
        
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
            
            [[HZAdLibrary sharedLibrary] pushAd: ad forAdUnit: bRequest.adUnit andTag: bRequest.tag];
            
            if ([[HZAdsManager sharedManager].statusDelegate respondsToSelector:@selector(didReceiveAdWithTag:)]) {
                [[HZAdsManager sharedManager].statusDelegate didReceiveAdWithTag:bRequest.tag];
            }
            
            if (completion) {
                completion(ad, bRequest.tag, nil);
            }
            
        } else {
            if ([[HZAdsManager sharedManager].statusDelegate respondsToSelector:@selector(didFailToReceiveAdWithTag:)]) {
                [[HZAdsManager sharedManager].statusDelegate didFailToReceiveAdWithTag:bRequest.tag];
            }
            
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
