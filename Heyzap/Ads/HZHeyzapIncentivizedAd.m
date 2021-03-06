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

static NSString *HZIncentivizedAdUserIdentifier = nil;
static int HZIncentivizedCreativeIDPin = 0;

@implementation HZHeyzapIncentivizedAd

+ (void)showForAuctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options
{
    if (![HZAdsManager isEnabled]) {
        return;
    }
    
    [[HZAdsManager sharedManager] showForCreativeType:HZCreativeTypeIncentivized auctionType:auctionType options:options];
}

+ (void)fetchForAuctionType:(HZAuctionType)auctionType completion:(void (^)(BOOL result, NSError *error))completion {
    if ([HZAdsManager isEnabled]) {
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (HZIncentivizedCreativeIDPin > 0) {
            [params setObject: [NSString stringWithFormat: @"%i", HZIncentivizedCreativeIDPin] forKey: @"creative_id"];
        }
        
        if (HZIncentivizedAdUserIdentifier != nil) {
            [params setObject: HZIncentivizedAdUserIdentifier forKey: @"user_identifier"];
        }
        
        HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithFetchableCreativeType:HZFetchableCreativeTypeVideo
                                                                                        tag:nil
                                                                                auctionType:auctionType
                                                                        andAdditionalParams:params];
        
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

+ (BOOL)isAvailableForTag:(NSString *)tag auctionType:(HZAuctionType)auctionType
{
    if (![HZAdsManager isEnabled]) return NO;
    return [[HZAdsManager sharedManager] isAvailableForFetchableCreativeType:HZFetchableCreativeTypeVideo auctionType:auctionType];
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZIncentivizedAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
