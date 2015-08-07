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
        
        _allowHide = [[HZDictionaryUtils objectForKey: @"allow_hide" ofClass: [NSNumber class] default: @0 dict: overriddenDefaults] boolValue];
        _allowSkip = [[HZDictionaryUtils objectForKey: @"allow_skip" ofClass: [NSNumber class] default: @0 dict: overriddenDefaults] boolValue];
        _allowInstallButton = [[HZDictionaryUtils objectForKey: @"allow_install_button" ofClass: [NSNumber class] default: @1 dict: overriddenDefaults] boolValue];
        _allowAdTimer = [[HZDictionaryUtils objectForKey: @"allow_ad_timer" ofClass: [NSNumber class] default: @1 dict: overriddenDefaults] boolValue];
        _lockoutTime = [HZDictionaryUtils objectForKey: @"lockout_time" ofClass: [NSNumber class] default: @0 dict: overriddenDefaults];
        _postRollInterstitial = [[HZDictionaryUtils objectForKey: @"post_roll_interstitial" ofClass: [NSNumber class] default: @0 dict: overriddenDefaults] boolValue];
        
        _installButtonText = [HZDictionaryUtils objectForKey:@"install_button_text" ofClass:[NSString class] default:@"Install Now" dict:overriddenDefaults];
        _skipNowText = [HZDictionaryUtils objectForKey:@"skip_now_text" ofClass:[NSString class] default:@"Skip" dict:overriddenDefaults];
        _skipLaterFormattedText = [HZDictionaryUtils objectForKey:@"skip_later_formatted_text" ofClass:[NSString class] default:@"Skip in %is" dict:overriddenDefaults];
        
        _allowFallbacktoStreaming = [[HZDictionaryUtils objectForKey: @"allow_streaming_fallback" ofClass: [NSNumber class] default: @0 dict: overriddenDefaults] boolValue];
        _forceStreaming = [[HZDictionaryUtils objectForKey: @"force_streaming" ofClass: [NSNumber class] default: @0 dict: overriddenDefaults] boolValue];
    }
    
    return self;
}

+ (HZVideoAdDisplayOptions *) defaults {
    return [[HZVideoAdDisplayOptions alloc] initWithDict:nil];
}

@end