//
//  HZInterstitialVideoConfig.m
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZInterstitialVideoConfig.h"
#import "HZDictionaryUtils.h"

@implementation HZInterstitialVideoConfig

NSString * const kHZInterstitialVideoIntervalKey = @"interstitial_video_interval";
NSString * const kHZInterstitialVideoEnabledKey  = @"interstitial_video_enabled";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _interstitialVideoIntervalMillis = [[HZDictionaryUtils objectForKey:kHZInterstitialVideoIntervalKey ofClass:[NSNumber class] default:@(30 * 1000) dict:dictionary] doubleValue];
        
        _interstitialVideoEnabled = [[HZDictionaryUtils objectForKey:kHZInterstitialVideoEnabledKey ofClass:[NSNumber class] default:@1 dict:dictionary] boolValue];
    }
    return self;
}

@end
