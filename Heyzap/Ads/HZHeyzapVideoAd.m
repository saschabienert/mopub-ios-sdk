//
//  HZHeyzapVideoAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZHeyzapVideoAd.h"
#import "HZAdsManager.h"
#import "HZAdLibrary.h"
#import "HZAdViewController.h"
#import "HZAdsFetchManager.h"
#import "HZAdFetchRequest.h"
#import "HZAdsAPIClient.h"

static int HZVideoAdCreativeIDPin = 0;

@implementation HZHeyzapVideoAd


+ (void)showForAuctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options {
    if (![HZAdsManager isEnabled]) {
        return;
    }

    [[HZAdsManager sharedManager] showForCreativeType:HZCreativeTypeVideo auctionType:auctionType options:options];
}

+ (void) hide {
    if ([HZAdsManager isEnabled]) {
        [[HZAdsManager sharedManager] hideActiveAd];
    }
}

+ (void) fetchForAuctionType:(HZAuctionType)auctionType withCompletion: (void (^)(BOOL result, NSError *error))completion {
    if ([HZAdsManager isEnabled]) {
        
        NSDictionary *params = (HZVideoAdCreativeIDPin > 0) ? @{@"creative_id": [NSString stringWithFormat: @"%i", HZVideoAdCreativeIDPin]} : nil;
        
        HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithFetchableCreativeType:HZFetchableCreativeTypeVideo
                                                                                        tag:nil
                                                                                auctionType:auctionType
                                                                        andAdditionalParams:params];
        
        [[HZAdsFetchManager sharedManager] fetch: request
                                  withCompletion:^(HZAdModel *ad, NSError *error) {
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

+ (BOOL) isAvailableForTag: (NSString *) tag auctionType:(HZAuctionType)auctionType {
    if (![HZAdsManager isEnabled]) return NO;
    return [[HZAdsManager sharedManager] isAvailableForFetchableCreativeType:HZFetchableCreativeTypeVideo auctionType:auctionType];
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
