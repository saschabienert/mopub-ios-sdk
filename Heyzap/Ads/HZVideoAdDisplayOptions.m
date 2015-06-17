//
//  HZVideoAdDisplayOptions.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZVideoAdDisplayOptions.h"
#import "HZDictionaryUtils.h"

@implementation HZVideoAdDisplayOptions

static NSDictionary *defaults;

+ (void) setDefaultsWithDict:(NSDictionary *)dict {
    
    defaults = dict;
}

- (instancetype) initWithDict:(NSDictionary *)dict {
    self = [super init];
    
    if(self) {
        NSMutableDictionary *overriddenDefaults = [defaults mutableCopy];
        [overriddenDefaults addEntriesFromDictionary:dict];
        
        _allowHide = [[HZDictionaryUtils hzObjectForKey: @"allow_hide" ofClass: [NSNumber class] default: @(0) withDict: overriddenDefaults] boolValue];
        _allowSkip = [[HZDictionaryUtils hzObjectForKey: @"allow_skip" ofClass: [NSNumber class] default: @(0) withDict: overriddenDefaults] boolValue];
        _allowInstallButton = [[HZDictionaryUtils hzObjectForKey: @"allow_install_button" ofClass: [NSNumber class] default: @(1) withDict: overriddenDefaults] boolValue];
        _allowAdTimer = [[HZDictionaryUtils hzObjectForKey: @"allow_ad_timer" ofClass: [NSNumber class] default: @(1) withDict: overriddenDefaults] boolValue];
        _lockoutTime = [HZDictionaryUtils hzObjectForKey: @"lockout_time" ofClass: [NSNumber class] default: @(0) withDict: overriddenDefaults];
        _postRollInterstitial = [[HZDictionaryUtils hzObjectForKey: @"post_roll_interstitial" ofClass: [NSNumber class] default: @(0) withDict: overriddenDefaults] boolValue];
        
        _installButtonText = [HZDictionaryUtils hzObjectForKey:@"install_button_text" ofClass:[NSString class] default:@"Install Now" withDict:overriddenDefaults];
        _skipNowText = [HZDictionaryUtils hzObjectForKey:@"skip_now_text" ofClass:[NSString class] default:@"Skip" withDict:overriddenDefaults];
        _skipLaterFormattedText = [HZDictionaryUtils hzObjectForKey:@"skip_later_formatted_text" ofClass:[NSString class] default:@"Skip in %is" withDict:overriddenDefaults];
        
        _allowFallbacktoStreaming = [[HZDictionaryUtils hzObjectForKey: @"allow_streaming_fallback" ofClass: [NSNumber class] default: @(0) withDict: overriddenDefaults] boolValue];
        _forceStreaming = [[HZDictionaryUtils hzObjectForKey: @"force_streaming" ofClass: [NSNumber class] default: @(0) withDict: overriddenDefaults] boolValue];
    }
    
    return self;
}

+ (HZVideoAdDisplayOptions *) defaults {
    return [[HZVideoAdDisplayOptions alloc] initWithDict:nil];
}

@end