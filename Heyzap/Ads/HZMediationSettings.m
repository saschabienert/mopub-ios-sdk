//
//  HZMediationSettings.m
//  Heyzap
//
//  Created by Monroe Ekilah on 7/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationSettings.h"
#import "HZDictionaryUtils.h"
#import "HeyzapAds.h"
#import "HZUtils.h"

#define kHZMediationCustomPublisherDataKey @"custom_publisher_data"
#define kHZMediationIncentivizedDailyLimit @"incentivized_daily_limit"
#define kHZMediationIAPAdDisableTime @"iap_ad_disable_time"
#define kHZMediationDisabledTags @"disabled_tags"

@interface HZMediationSettings()

@property (nonatomic) NSTimeInterval IAPAdDisableTime;
@property (nonatomic) NSTimeInterval IAPAdsTimeOut;

@end

@implementation HZMediationSettings

NSString * const kHZMediationUserDefaultsKeyIncentivizedCounter = @"kHZMediationUserDefaultsKeyIncentivizedCounter";
NSString * const kHZMediationUserDefaultsKeyIncentivizedDate = @"kHZMediationUserDefaultsKeyIncentivizedDate";

#pragma mark - Initialization

- (instancetype) init
{
    self = [super init];
    if(self) {
        _remoteDataDictionary = [[NSDictionary alloc] init];
        _disabledTags = [NSSet set];
    }
    
    return self;
}

- (void) setupWithDict:(NSDictionary *)dictionary fromCache:(BOOL)fromCache{
    _IAPAdDisableTime = [[HZDictionaryUtils hzObjectForKey:kHZMediationIAPAdDisableTime
                                                       ofClass:[NSNumber class]
                                                       default:@0
                                                      withDict:dictionary] longLongValue] * 60; // in seconds
    
    _incentivizedDailyLimit = [HZDictionaryUtils hzObjectForKey:kHZMediationIncentivizedDailyLimit
                                                            ofClass:[NSNumber class]
                                                            default:nil
                                                           withDict:dictionary];
    
    NSArray *disabledTags = [HZDictionaryUtils hzObjectForKey:kHZMediationDisabledTags
                                                      ofClass:[NSArray class]
                                                      default:@[]
                                                     withDict:dictionary];
    _disabledTags = [NSSet setWithArray:disabledTags];
    
    NSString *jsonString = [HZDictionaryUtils hzObjectForKey:kHZMediationCustomPublisherDataKey
                                                     ofClass:[NSString class]
                                                     default: @"{}"
                                                    withDict:dictionary];
    
    // converts string like "{\"test\":\"foo\"}" to dictionary
    if(jsonString == nil) {
        _remoteDataDictionary = @{};
    } else {
        NSError *error;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:kNilOptions error:&error];
        _remoteDataDictionary = (error ? @{} : json);
    }
    
    if(!fromCache){
        [[NSNotificationCenter defaultCenter] postNotificationName:HZRemoteDataRefreshedNotification object:nil userInfo:_remoteDataDictionary];
    }
}

#pragma mark - Settings

- (NSTimeInterval) IAPAdsTimeOut {
    if (_IAPAdsTimeOut < [NSDate timeIntervalSinceReferenceDate]) {
        _IAPAdsTimeOut = 0;
    }
    return _IAPAdsTimeOut;
}

- (void) startIAPAdsTimeOut {
    self.IAPAdsTimeOut = [[NSDate dateWithTimeIntervalSinceNow:self.IAPAdDisableTime] timeIntervalSinceReferenceDate];
}

- (BOOL) tagIsEnabled:(NSString *)tag {
    HZParameterAssert(tag);
    return ![self.disabledTags containsObject:tag];
}

- (BOOL) shouldAllowIncentivizedAd {
    if(!self.incentivizedDailyLimit) {
        return YES;
    }
    
    NSNumber *incentivizedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kHZMediationUserDefaultsKeyIncentivizedCounter];
    NSDate *incentivizedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kHZMediationUserDefaultsKeyIncentivizedDate];
    
    if(!incentivizedDate || !incentivizedCount) {
        return YES;
    }
    
    // currently vulnerable to users changing their system clock. could be mitigated if the server reported today's date & we used that everywhere.
    if(![HZUtils dateIsToday:incentivizedDate]) {
        return YES;
    }
    
    // we've shown incentivized videos today. compare to limit
    if(incentivizedCount.intValue < self.incentivizedDailyLimit.intValue) {
        return YES;
    }
    
    return NO;
}

- (void) incentivizedAdShown {
    NSNumber *incentivizedCount;
    NSDate *incentivizedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kHZMediationUserDefaultsKeyIncentivizedDate];
    
    // check if the currently stored incentivized count is stale or not
    if ([HZUtils dateIsToday:incentivizedDate]) {
        incentivizedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kHZMediationUserDefaultsKeyIncentivizedCounter] ?: @0;
        incentivizedCount = @(incentivizedCount.intValue + 1);
    } else {
        incentivizedCount = @1;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:incentivizedCount forKey:kHZMediationUserDefaultsKeyIncentivizedCounter];
    [[NSUserDefaults standardUserDefaults] setObject:[HZUtils dateWithoutTimeFromDate:[NSDate date]] forKey:kHZMediationUserDefaultsKeyIncentivizedDate];
}

@end