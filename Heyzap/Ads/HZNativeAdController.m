//
//  HZNativeAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZNativeAdController.h"
#import "HZAdFetchRequest.h"
#import "HZAdsAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZNativeAd.h"
#import "HZNativeAdCollection.h"
#import "HeyzapAds.h"

#import "HZNativeAdCollection_Private.h"
#import "HZNativeAd_Private.h"

@implementation HZNativeAdController

+ (void)fetchAds:(const NSUInteger)numberOfAds
             tag:(NSString *)tag
      completion:(void (^)(NSError *error, HZNativeAdCollection *collection))completion {
    NSParameterAssert(numberOfAds > 0);
    NSParameterAssert(completion);
    if (!tag) {
        tag = [HeyzapAds defaultTagName];
    }
    
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:@[@"native"]
                                                                         adUnit:@"native"
                                                                            tag:tag
                                                            andAdditionalParams:@{@"max_count": @(numberOfAds)}];
    
    
    [[HZAdsAPIClient sharedClient] loadRequest:request withCompletion:^(HZAdFetchRequest *request) {
        if (request.lastError) {
            NSError *error = [NSError errorWithDomain:@"heyzap" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to get response from server", NSUnderlyingErrorKey: request.lastError}];
            completion(error, nil);
            return;
        }
        
        NSDictionary *response = request.lastResponse;
        NSArray *adsArray = [HZDictionaryUtils hzObjectForKey:@"ads" ofClass:[NSArray class] withDict:response];
        
        HZNativeAdCollection *const collection = ({
            NSMutableArray *ads = [NSMutableArray array];
            for (NSDictionary *ad in adsArray) {
                HZNativeAd *adModel = [[HZNativeAd alloc]initWithDictionary:ad];
                if (adModel) {
                    [ads addObject:adModel];
                } else {
                    HZELog(@"Invalid native ad model");
                }
            }
            [[HZNativeAdCollection alloc] initWithAds:ads];
        });
        
        if (!collection) {
            NSError *error = [NSError errorWithDomain:@"heyzap" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create native ads from server"}];
            completion(error, nil);
        } else {
            completion(nil, collection);
        }
        
    }];
}

@end
