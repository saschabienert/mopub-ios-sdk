//
//  HZMediationInterstitialVideoManager.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationInterstitialVideoManager.h"
#import "HZDictionaryUtils.h"

@interface HZMediationInterstitialVideoManager ()
@property (nonatomic) double interstitialVideoIntervalMillis;
@property (nonatomic) BOOL interstitialVideoEnabled;
@property (nonatomic) NSDate *lastInterstitialVideoShownDate;
@end


@implementation HZMediationInterstitialVideoManager

NSString * const kHZInterstitialVideoIntervalKey = @"interstitial_video_interval";
NSString * const kHZInterstitialVideoEnabledKey  = @"interstitial_video_enabled";

- (instancetype) initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self updateWithDictionary:dictionary];
    }
    return self;
}

- (void) updateWithDictionary:(NSDictionary *)dictionary {
    self.interstitialVideoIntervalMillis = [[HZDictionaryUtils objectForKey:kHZInterstitialVideoIntervalKey ofClass:[NSNumber class] default:@(30 * 1000) dict:dictionary] doubleValue];
    self.interstitialVideoEnabled = [[HZDictionaryUtils objectForKey:kHZInterstitialVideoEnabledKey ofClass:[NSNumber class] default:@1 dict:dictionary] boolValue];
}

- (void) didShowInterstitialVideo {
    self.lastInterstitialVideoShownDate = [NSDate date];
}


#pragma mark - Queries

- (BOOL) shouldAllowInterstitialVideo {
    return self.interstitialVideoEnabled && [self hasEnoughTimePassedSinceLastInterstitialVideo];
}

- (NSSet <NSNumber *> *) creativeTypesAllowedToShowForAdType:(HZAdType)adType {
    switch(adType){
        case HZAdTypeInterstitial:
            if([self shouldAllowInterstitialVideo])
                return [NSSet setWithArray:@[@(HZCreativeTypeVideo), @(HZCreativeTypeStatic)]];
            else
                return [NSSet setWithArray:@[@(HZCreativeTypeStatic)]];
        case HZAdTypeIncentivized:
            return [NSSet setWithArray:@[@(HZCreativeTypeIncentivized)]];
        case HZAdTypeBanner:
            return [NSSet setWithArray:@[@(HZCreativeTypeBanner)]];
        case HZAdTypeVideo:
            return [NSSet setWithArray:@[@(HZCreativeTypeVideo)]];
    }
}


#pragma mark - Utilities

- (BOOL) hasEnoughTimePassedSinceLastInterstitialVideo {
    if (!self.lastInterstitialVideoShownDate) {
        return YES;
    }
    const NSTimeInterval secondsSinceLastInterstitial = [[NSDate date] timeIntervalSinceDate:self.lastInterstitialVideoShownDate];
    return (secondsSinceLastInterstitial * 1000) > self.interstitialVideoIntervalMillis;
}


@end
