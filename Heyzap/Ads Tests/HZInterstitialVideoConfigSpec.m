//
//  HZMediationInterstitialVideoManagerSpec.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright 2015 Heyzap. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "HZMediationInterstitialVideoManager.h"
#import "HZMediationConstants.h"

SPEC_BEGIN(HZMediationInterstitialVideoManagerSpec)

describe(@"HZMediationInterstitialVideoManager", ^{
    
    
    NSNumber const *longInterval = @100000;
    NSNumber const *noInterval = @0;
    NSNumber const *shortInterval = @500;
    
    NSDictionary *initDisabledLongInterval = @{kHZInterstitialVideoIntervalKey:longInterval, kHZInterstitialVideoEnabledKey:@NO};
    NSDictionary *initEnabledLongInterval = @{kHZInterstitialVideoIntervalKey:longInterval, kHZInterstitialVideoEnabledKey:@YES};
    NSDictionary *initEnabledNoInterval= @{kHZInterstitialVideoIntervalKey:noInterval, kHZInterstitialVideoEnabledKey:@YES};
    NSDictionary *initEnabledShortInterval= @{kHZInterstitialVideoIntervalKey:shortInterval, kHZInterstitialVideoEnabledKey:@YES};
    
    it(@"Parses correctly on init and updates", ^{
        HZMediationInterstitialVideoManager *config = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:initDisabledLongInterval];
        [[theValue(config.interstitialVideoIntervalMillis) should] equal:longInterval];
        [[theValue(config.interstitialVideoEnabled) should] equal:@NO];
        
        [config updateWithDictionary:initEnabledNoInterval];
        [[theValue(config.interstitialVideoIntervalMillis) should] equal:noInterval];
        [[theValue(config.interstitialVideoEnabled) should] equal:@YES];
    });
    
    it(@"Updates don't corrupt current timeout, but an update with interval smaller than current timeout period should work", ^{
        HZMediationInterstitialVideoManager *config = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:initEnabledLongInterval];
        [[theValue(config.interstitialVideoIntervalMillis) should] equal:longInterval];
        [[theValue(config.interstitialVideoEnabled) should] equal:@YES];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@YES];
        
        [config didShowInterstitialVideo];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@NO];
        
        [config updateWithDictionary:initEnabledLongInterval];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@NO];
        
        [config updateWithDictionary:initEnabledNoInterval];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@YES];
    });
    
    it(@"Defaults to enabled w/ non-zero interval", ^{
        HZMediationInterstitialVideoManager *config = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:@{}];
        [[theValue(config.interstitialVideoEnabled) should] equal:@YES];
        [[theValue(config.interstitialVideoIntervalMillis) shouldNot] equal:noInterval];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@YES];
    });
    
    it(@"Stops interstitial videos when they are disabled", ^{
        HZMediationInterstitialVideoManager *config = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:initDisabledLongInterval];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@NO];
        NSSet <NSNumber *> *creativeTypesAllowed = [config creativeTypesAllowedToShowForAdType:HZAdTypeInterstitial];
        [[theValue([creativeTypesAllowed containsObject:@(HZCreativeTypeVideo)]) should] equal:@NO];
    });
    
    it(@"Stops interstitial videos when they are enabled but should be on a timeout", ^{
        HZMediationInterstitialVideoManager *config = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:initEnabledLongInterval];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@YES];
        
        [config didShowInterstitialVideo];
        
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@NO];
        NSSet <NSNumber *> *creativeTypesAllowed = [config creativeTypesAllowedToShowForAdType:HZAdTypeInterstitial];
        [[theValue([creativeTypesAllowed containsObject:@(HZCreativeTypeVideo)]) should] equal:@NO];
    });
    
    it(@"Re-enables interstitial videos after the timeout expires", ^{
        HZMediationInterstitialVideoManager *config = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:initEnabledShortInterval];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@YES];
        
        [config didShowInterstitialVideo];
        
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@NO];
        [[expectFutureValue(theValue([config shouldAllowInterstitialVideo])) hzShouldEventuallyAfterDelay] equal:@YES];
    });
    
    it(@"Allows interstitial videos when they are enabled and not on a timeout", ^{
        HZMediationInterstitialVideoManager *config = [[HZMediationInterstitialVideoManager alloc] initWithDictionary:initEnabledLongInterval];
        [[theValue([config shouldAllowInterstitialVideo]) should] equal:@YES];
        NSSet <NSNumber *> *creativeTypesAllowed = [config creativeTypesAllowedToShowForAdType:HZAdTypeInterstitial];
        [[creativeTypesAllowed should] equal:hzCreativeTypesPossibleForAdType(HZAdTypeInterstitial)];
    });
});

SPEC_END
