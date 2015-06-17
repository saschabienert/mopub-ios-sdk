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

static NSNumber *lockoutTimeDefault;
static BOOL allowSkipDefault;
static BOOL allowHideDefault;
static BOOL allowInstallButtonDefault;
static BOOL allowAdTimerDefault;
static BOOL postRollInterstitialDefault;
static NSString *installButtonTextDefault;
static NSString *skipNowTextDefault;
static NSString *skipLaterFormattedTextDefault;
static BOOL allowFallbackToStreamingDefault;
static BOOL forceStreamingDefault;

+ (void) setDefaultsWithDict:(NSDictionary *)dict {
    allowHideDefault = [[HZDictionaryUtils hzObjectForKey: @"allow_hide" ofClass: [NSNumber class] default: @(0) withDict: dict] boolValue];
    allowSkipDefault = [[HZDictionaryUtils hzObjectForKey: @"allow_skip" ofClass: [NSNumber class] default: @(0) withDict: dict] boolValue];
    allowInstallButtonDefault = [[HZDictionaryUtils hzObjectForKey: @"allow_install_button" ofClass: [NSNumber class] default: @(1) withDict: dict] boolValue];
    allowAdTimerDefault = [[HZDictionaryUtils hzObjectForKey: @"allow_ad_timer" ofClass: [NSNumber class] default: @(1) withDict: dict] boolValue];
    lockoutTimeDefault = [HZDictionaryUtils hzObjectForKey: @"lockout_time" ofClass: [NSNumber class] default: @(0) withDict: dict];
    postRollInterstitialDefault = [[HZDictionaryUtils hzObjectForKey: @"post_roll_interstitial" ofClass: [NSNumber class] default: @(0) withDict: dict] boolValue];
    
    installButtonTextDefault = [HZDictionaryUtils hzObjectForKey:@"install_button_text" ofClass:[NSString class] default:@"Install Now" withDict:dict];
    skipNowTextDefault = [HZDictionaryUtils hzObjectForKey:@"skip_now_text" ofClass:[NSString class] default:@"Skip" withDict:dict];
    skipLaterFormattedTextDefault = [HZDictionaryUtils hzObjectForKey:@"skip_later_formatted_text" ofClass:[NSString class] default:@"Skip in %is" withDict:dict];
    
    allowFallbackToStreamingDefault = [[HZDictionaryUtils hzObjectForKey: @"allow_streaming_fallback" ofClass: [NSNumber class] default: @(0) withDict: dict] boolValue];
    forceStreamingDefault = [[HZDictionaryUtils hzObjectForKey: @"force_streaming" ofClass: [NSNumber class] default: @(0) withDict: dict] boolValue];
}

- (instancetype) initWithDict:(NSDictionary *)dict {
    self = [super init];
    
    if(self) {
        _allowHide = [[HZDictionaryUtils hzObjectForKey: @"allow_hide" ofClass: [NSNumber class] default: @(allowHideDefault) withDict: dict] boolValue];
        _allowSkip = [[HZDictionaryUtils hzObjectForKey: @"allow_skip" ofClass: [NSNumber class] default: @(allowSkipDefault) withDict: dict] boolValue];
        _allowInstallButton = [[HZDictionaryUtils hzObjectForKey: @"allow_install_button" ofClass: [NSNumber class] default: @(allowInstallButtonDefault) withDict: dict] boolValue];
        _allowAdTimer = [[HZDictionaryUtils hzObjectForKey: @"allow_ad_timer" ofClass: [NSNumber class] default: @(allowAdTimerDefault) withDict: dict] boolValue];
        _lockoutTime = [HZDictionaryUtils hzObjectForKey: @"lockout_time" ofClass: [NSNumber class] default: lockoutTimeDefault withDict: dict];
        _postRollInterstitial = [[HZDictionaryUtils hzObjectForKey: @"post_roll_interstitial" ofClass: [NSNumber class] default: @(postRollInterstitialDefault) withDict: dict] boolValue];
        
        _installButtonText = [HZDictionaryUtils hzObjectForKey:@"install_button_text" ofClass:[NSString class] default:installButtonTextDefault withDict:dict];
        _skipNowText = [HZDictionaryUtils hzObjectForKey:@"skip_now_text" ofClass:[NSString class] default:skipNowTextDefault withDict:dict];
        _skipLaterFormattedText = [HZDictionaryUtils hzObjectForKey:@"skip_later_formatted_text" ofClass:[NSString class] default:skipLaterFormattedTextDefault withDict:dict];
        
        _allowFallbacktoStreaming = [[HZDictionaryUtils hzObjectForKey: @"allow_streaming_fallback" ofClass: [NSNumber class] default: @(allowFallbackToStreamingDefault) withDict: dict] boolValue];
        _forceStreaming = [[HZDictionaryUtils hzObjectForKey: @"force_streaming" ofClass: [NSNumber class] default: @(forceStreamingDefault) withDict: dict] boolValue];
    }
    
    return self;
}

+ (HZVideoAdDisplayOptions *) defaults {
    return [[HZVideoAdDisplayOptions alloc] initWithDict:nil];
}

@end