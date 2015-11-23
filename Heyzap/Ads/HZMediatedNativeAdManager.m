//
//  HZMediatedNativeAdManager.m
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediatedNativeAdManager_Private.h"
#import "HZFetchOptions_Private.h"

@implementation HZMediatedNativeAdManager

+ (void)fetchNativeAdWithOptions:(HZFetchOptions *)fetchOptions {
    fetchOptions.requestingAdType = HZAdTypeNative;
    [[HeyzapMediation sharedInstance] fetchWithOptions:fetchOptions];
}

+ (HZMediatedNativeAd *)getNextNativeAdForTag:(NSString *)tag error:(NSError **)error {
    return [self getNextNativeAdForTag:tag additionalParams:@{} error:error];
}

+ (HZMediatedNativeAd *)getNextNativeAdForTag:(NSString *)tag additionalParams:(NSDictionary *)additionalParams error:(NSError **)error {
    tag = tag ?: [HeyzapAds defaultTagName];
    return [[HeyzapMediation sharedInstance] getNextNativeAd:tag additionalParams:additionalParams error:error];
}

@end
