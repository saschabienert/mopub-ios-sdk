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

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _interstitialVideoIntervalMillis = [[HZDictionaryUtils hzObjectForKey:@"interstitial_video_interval" ofClass:[NSNumber class] default:@(30 * 1000) withDict:dictionary] doubleValue];
        
        _interstitialVideoEnabled = [[HZDictionaryUtils hzObjectForKey:@"interstitial_video_enabled" ofClass:[NSNumber class] default:@1 withDict:dictionary] boolValue];
    }
    return self;
}

@end
