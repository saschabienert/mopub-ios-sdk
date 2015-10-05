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


- (instancetype)initWithDefaultsDictionary:(NSDictionary *const)defaultsDictionary adUnitDictionary:(NSDictionary *const)adUnitDictionary {
    self = [super init];
    
    if(self) {
        NSDictionary *const finalSettings = ({
            NSMutableDictionary *settings = [defaultsDictionary mutableCopy];
            [settings addEntriesFromDictionary:adUnitDictionary];
            settings;
        });
        
        _allowHide = [[HZDictionaryUtils objectForKey: @"allow_hide" ofClass: [NSNumber class] default: @0 dict: finalSettings] boolValue];
        _allowSkip = [[HZDictionaryUtils objectForKey: @"allow_skip" ofClass: [NSNumber class] default: @0 dict: finalSettings] boolValue];
        _allowInstallButton = [[HZDictionaryUtils objectForKey: @"allow_install_button" ofClass: [NSNumber class] default: @1 dict: finalSettings] boolValue];
        _allowAdTimer = [[HZDictionaryUtils objectForKey: @"allow_ad_timer" ofClass: [NSNumber class] default: @1 dict: finalSettings] boolValue];
        _lockoutTime = [HZDictionaryUtils objectForKey: @"lockout_time" ofClass: [NSNumber class] default: @0 dict: finalSettings];
        _postRollInterstitial = [[HZDictionaryUtils objectForKey: @"post_roll_interstitial" ofClass: [NSNumber class] default: @0 dict: finalSettings] boolValue];
        
        _installButtonText = [HZDictionaryUtils objectForKey:@"install_button_text" ofClass:[NSString class] default:@"Install Now" dict:finalSettings];
        _skipNowText = [HZDictionaryUtils objectForKey:@"skip_now_text" ofClass:[NSString class] default:@"Skip" dict:finalSettings];
        _skipLaterFormattedText = [HZDictionaryUtils objectForKey:@"skip_later_formatted_text" ofClass:[NSString class] default:@"Skip in %is" dict:finalSettings];
        
        _allowFallbacktoStreaming = [[HZDictionaryUtils objectForKey: @"allow_streaming_fallback" ofClass: [NSNumber class] default: @0 dict: finalSettings] boolValue];
        _forceStreaming = [[HZDictionaryUtils objectForKey: @"force_streaming" ofClass: [NSNumber class] default: @0 dict: finalSettings] boolValue];
    }
    
    return self;
}

@end