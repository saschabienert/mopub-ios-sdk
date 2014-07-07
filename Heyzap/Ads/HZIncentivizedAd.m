//
//  HZIncentivizedAd.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdsManager.h"
#import "HZAdViewController.h"
#import "HZAdLibrary.h"
#import "HZAdFetchRequest.h"
#import "HZAdsFetchManager.h"

#define HZIncentivizedAdUnit @"incentivized"
#define HZIncentivizedAdCreativeTypes @[@"video", @"interstitial_video"]

#import "HZIncentivizedAd.h"

static NSString *HZIncentivizedAdUserIdentifier = nil;
static int HZIncentivizedCreativeIDPin = 0;

@implementation HZIncentivizedAd

+ (void) setDelegate:(id<HZIncentivizedAdDelegate>) delegate {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] setIncentivizedDelegate: delegate];
    }
}

+ (void) show {
    [self showForTag: [HeyzapAds defaultTagName]];
}

+ (void) showForTag: (NSString *) tag {
    if (![[HZAdsManager sharedManager] isEnabled]) {
        return;
    }
    
    [[HZAdsManager sharedManager] showForAdUnit: HZIncentivizedAdUnit andTag: tag withCompletion: nil];

}

+ (void) hide {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] hideActiveAd];
    }
}

+ (void) fetch {
    [self fetchForTag: [HeyzapAds defaultTagName] withCompletion: nil];
}

+ (void) fetchWithCompletion:(void (^)(BOOL, NSError *))completion {
    [self fetchForTag: [HeyzapAds defaultTagName] withCompletion: completion];
}

+ (void) fetchForTag:(NSString *)tag {
    [self fetchForTag: tag withCompletion: nil];
}

+ (void) fetchForTag: (NSString *) tag withCompletion:(void (^)(BOOL, NSError *))completion {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (HZIncentivizedCreativeIDPin > 0) {
            [params setObject: [NSString stringWithFormat: @"%i", HZIncentivizedCreativeIDPin] forKey: @"creative_id"];
        }
        
        if (HZIncentivizedAdUserIdentifier != nil) {
            [params setObject: HZIncentivizedAdUserIdentifier forKey: @"user_identifier"];
        }
        
        HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes: HZIncentivizedAdCreativeTypes
                                                                             adUnit: HZIncentivizedAdUnit
                                                                                tag: tag
                                                                andAdditionalParams: params];
        
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

+ (void) setUserIdentifier: (NSString *) userIdentifier {
    HZIncentivizedAdUserIdentifier = userIdentifier;
}

+ (void) setCreativeID:(int)creativeID {
    if (creativeID > 0) {
        HZIncentivizedCreativeIDPin = creativeID;
    } else {
        HZIncentivizedCreativeIDPin = 0;
    }
}

+ (BOOL) isAvailable {
    return [self isAvailableForTag: [HeyzapAds defaultTagName]];
}

+ (BOOL) isAvailableForTag: (NSString *) tag {
    if (![[HZAdsManager sharedManager] isEnabled]) return NO;
    
    return [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit: HZIncentivizedAdUnit withTag: tag] != nil;
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZIncentivizedAd' is a static class and cannot be instantiated."];
    return nil;
}


@end
