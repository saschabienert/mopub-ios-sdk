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

static NSString *HZIncentivizedAdUserIdentifier = nil;
static int HZIncentivizedCreativeIDPin = 0;

@implementation HZHeyzapIncentivizedAd

+ (void)setDelegate:(id<HZIncentivizedAdDelegate>)delegate
{
    if ([[HZAdsManager sharedManager] isEnabled]) {
        [[HZAdsManager sharedManager] setIncentivizedDelegate:delegate];
    }
}

+ (void) show {
    if (![[HZAdsManager sharedManager] isEnabled]) {
        return;
    }
    
    [[HZAdsManager sharedManager] showForAdUnit: HZIncentivizedAdUnit andTag: [HeyzapAds defaultTagName] withCompletion: nil];
}

+ (void) fetchWithCompletion:(void (^)(BOOL, NSError *))completion {
    if ([[HZAdsManager sharedManager] isEnabled]) {
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (HZIncentivizedCreativeIDPin > 0) {
            [params setObject: [NSString stringWithFormat: @"%i", HZIncentivizedCreativeIDPin] forKey: @"creative_id"];
        }
        
        if (HZIncentivizedAdUserIdentifier != nil) {
            [params setObject: HZIncentivizedAdUserIdentifier forKey: @"user_identifier"];
        }
        
        HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes: HZIncentivizedAdCreativeTypes adUnit: HZIncentivizedAdUnit tag: [HeyzapAds defaultTagName] andAdditionalParams: params];
        
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
    if (![[HZAdsManager sharedManager] isEnabled]) return NO;
    
    return [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit: HZIncentivizedAdUnit withTag: [HeyzapAds defaultTagName]] != nil;
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZIncentivizedAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
