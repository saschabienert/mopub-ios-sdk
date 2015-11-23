//
//  HZFetchOptions.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZFetchOptions.h"
#import "HZFetchOptions_Private.h"
#import "HZFetchOptions_HeyzapMediationPrivate.h"
#import "HeyzapAds.h"
#import "HZAdModel.h"
#import "HZMediationConstants.h"
#import "HZUtils.h"

NSString * const kHZGADAdLoaderAdTypeNativeAppInstall = @"2";
NSString * const kHZGADAdLoaderAdTypeNativeContent = @"1";

@implementation HZFetchOptions

- (instancetype) init {
    self = [super init];
    if (self) {
        _creativeTypesToFetch = [NSSet new];
        _creativeTypesFetchesFinished= [NSSet new];
        _alreadyNotifiedDelegateOfSuccess = NO;
    }
    
    return self;
}

@synthesize tag = _tag;

- (NSArray *)admobNativeAdTypes {
    if (!_admobNativeAdTypes) {
        return hzAllAdmobAdTypes();
    } else {
        return _admobNativeAdTypes;
    }
}

- (NSNumber *)uniqueNativeAdsToFetch {
    if (!_uniqueNativeAdsToFetch) {
        return @20;
    } else {
        return _uniqueNativeAdsToFetch;
    }
}

- (NSString *)tag {
    if (_tag == nil) {
        _tag = [HeyzapAds defaultTagName];
    }
    
    return _tag;
}

- (void) setTag:(nullable NSString *)tag {
    _tag = [HZAdModel normalizeTag:tag];
}

- (id)copyWithZone:(NSZone *)zone {
    HZFetchOptions *copy = [[HZFetchOptions alloc] init];
    copy.tag = self.tag;
    copy.requestingAdType = self.requestingAdType;
    copy.additionalParameters = self.additionalParameters;
    copy.completion = self.completion;
    copy.placementIDOverride = self.placementIDOverride;
    copy.alreadyNotifiedDelegateOfSuccess = self.alreadyNotifiedDelegateOfSuccess;
    copy.creativeTypesToFetch = self.creativeTypesToFetch;
    copy.creativeTypesFetchesFinished = self.creativeTypesFetchesFinished;
    copy.presentingViewController = self.presentingViewController;
    copy.uniqueNativeAdsToFetch = self.uniqueNativeAdsToFetch;
    copy.admobNativeAdTypes = self.admobNativeAdTypes;
    copy.admobPreferredImageOrientation = self.admobPreferredImageOrientation;
    return copy;
}

NSArray <NSString *>*hzAllAdmobAdTypes(void) {
    return @[
             hzAdMobNativeAdTypeAppInstall(),
             hzAdMobNativeAdTypeContent(),
             ];
}

NSString *hzAdMobNativeAdTypeAppInstall(void) {
    return hzLookupStringConstant(@"kGADAdLoaderAdTypeNativeAppInstall") ?: kHZGADAdLoaderAdTypeNativeAppInstall;
}
NSString *hzAdMobNativeAdTypeContent(void) {
    return hzLookupStringConstant(@"kGADAdLoaderAdTypeNativeContent") ?: kHZGADAdLoaderAdTypeNativeContent;
}

@end