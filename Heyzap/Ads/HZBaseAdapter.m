//
//  HZBaseAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZBaseAdapter.h"
#import "HZVungleAdapter.h"
#import "HZChartboostAdapter.h"
#import "HZMediationConstants.h"
#import "HZAdColonyAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZHeyzapAdapter.h"
#import "HZAppLovinAdapter.h"
#import "HZUnityAdsAdapter.h"
#import "HZCrossPromoAdapter.h"
#import "HZFacebookAdapter.h"
#import "HZiAdAdapter.h"
#import "HZBannerAdapter.h"
#import "HZHyprmxAdapter.h"

@implementation HZBaseAdapter

#define ABSTRACT_METHOD_ERROR() @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Subclasses should override this method" userInfo:nil];

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    ABSTRACT_METHOD_ERROR();
}

#pragma mark - Adapter Protocol

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    ABSTRACT_METHOD_ERROR();
}

+ (BOOL)isSDKAvailable
{
    ABSTRACT_METHOD_ERROR();
}

+ (NSString *)name
{
    ABSTRACT_METHOD_ERROR();
}


+ (NSString *)humanizedName {
    ABSTRACT_METHOD_ERROR();
}

+ (NSString *)sdkVersion
{
    ABSTRACT_METHOD_ERROR();
}

- (HZAdType)supportedAdFormats
{
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)isVideoOnlyNetwork
{
    // Return true for video-only networks like Vungle, whose interstitial support is faked via videos.
    ABSTRACT_METHOD_ERROR();
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    ABSTRACT_METHOD_ERROR();
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options
{
    ABSTRACT_METHOD_ERROR();
}

- (HZBannerAdapter *)fetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate {
    return nil;
}
- (BOOL)hasBannerCredentials {
    return NO;
}

#pragma mark - Inferred methods

- (NSString *)sdkVersion
{
    return [[self class] sdkVersion];
}

- (NSString *)name
{
    return [[self class] name];
}

- (BOOL)supportsAdType:(HZAdType)adType
{
    return [self supportedAdFormats] & adType;
}

- (NSError *)lastErrorForAdType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            return self.lastInterstitialError;
            break;
        }
        case HZAdTypeIncentivized: {
            return self.lastIncentivizedError;
            break;
        }
        case HZAdTypeVideo: {
            return self.lastVideoError;
            break;
        }
        case HZAdTypeBanner: {
            // ignored
            return nil;
        }
    }
}

- (void)clearErrorForAdType:(HZAdType)adType
{
    switch (adType) {
        case HZAdTypeInterstitial: {
            self.lastInterstitialError = nil;
            break;
        }
        case HZAdTypeIncentivized: {
            self.lastIncentivizedError = nil;
            break;
        }
        case HZAdTypeVideo: {
            self.lastVideoError = nil;
            break;
        }
        case HZAdTypeBanner: {
            // ignored for now
            break;
        }
    }
}

#pragma mark - Implemented Methods

+ (Class)adapterClassForName:(NSString *)adapterName
{
    for (Class klass in [self allAdapterClasses]) {
        if ([[klass name] isEqualToString: adapterName]) {
            return klass;
        }
    }
    
    return nil;
}

+ (NSSet *)allAdapterClasses
{
    return [NSSet setWithObjects:
            [HZVungleAdapter class],
            [HZChartboostAdapter class],
            [HZAdColonyAdapter class],
            [HZAdMobAdapter class],
            [HZHeyzapAdapter class],
            [HZAppLovinAdapter class],
            [HZCrossPromoAdapter class],
            [HZUnityAdsAdapter class],
            [HZCrossPromoAdapter class],
            [HZFacebookAdapter class],
            [HZiAdAdapter class],
            [HZHyprmxAdapter class],
            nil];
}

+ (NSArray *)testActivityAdapters
{
    NSSet *filteredAdapters = [[self allAdapterClasses] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^
        BOOL(HZBaseAdapter *adapter, NSDictionary *bindings) {
        return [adapter class] != [HZCrossPromoAdapter class];
    }]];

    NSArray *sortedAdapters = [[filteredAdapters allObjects] sortedArrayUsingComparator:^
        NSComparisonResult(HZBaseAdapter *obj1, HZBaseAdapter *obj2) {
        return [[obj1 name] compare:[obj2 name]];
    }];

    return sortedAdapters;
}

+ (BOOL)isHeyzapAdapter {
    return NO;
}

@end
