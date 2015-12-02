//
//  HZHardcodedConstantChecker.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/22/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZHardcodedConstantChecker.h"

#import <VungleSDK/VungleSDK.h>
#import "HZVungleAdapter.h"
@import GoogleMobileAds;

#define COMPARE_CONSTANTS(real, hardcoded) \
do { \
if (![real isEqualToString:hardcoded]) { \
    @throw [NSException exceptionWithName:@"Invalid hardcoded constant" reason: @"The constant " #real @" did not match the hardcoded constant " #hardcoded userInfo:@{@"Real value" : real, @"Hardcoded value": hardcoded}]; \
} \
} while (0)


@implementation HZHardcodedConstantChecker

+ (void)checkConstants {
    
    COMPARE_CONSTANTS(VunglePlayAdOptionKeyPlacement, HZFallbackVunglePlayAdOptionKeyPlacement);
    COMPARE_CONSTANTS(VunglePlayAdOptionKeyIncentivized, HZFallbackVunglePlayAdOptionKeyIncentivized);
    COMPARE_CONSTANTS(kGADAdLoaderAdTypeNativeAppInstall, kHZGADAdLoaderAdTypeNativeAppInstall);
    COMPARE_CONSTANTS(kGADAdLoaderAdTypeNativeContent, kHZGADAdLoaderAdTypeNativeContent);
}

@end
