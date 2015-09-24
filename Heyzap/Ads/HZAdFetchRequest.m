//
//  HZAdFetchRequest.m
//  Heyzap
//
//  Created by Daniel Rhodes on 1/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAdFetchRequest.h"
#import <UIKit/UIKit.h>
#import "HeyzapAds.h"
#import "HZAdsManager.h"
#import "HZAdModel.h"
#import "HZUtils.h"
#import "HZDevice.h"

#define kHZAdRetries 3

@interface HZAdFetchRequest()
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic) NSMutableDictionary *generatedParams;
@end

@implementation HZAdFetchRequest

- (id) initWithFetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType
                                 tag:(NSString *)tag
                         auctionType:(HZAuctionType)auctionType
                 andAdditionalParams:(NSDictionary *)additionalParams {
    
    self = [super init];
    if (self) {
        _fetchableCreativeType = fetchableCreativeType;
        _auctionType = auctionType;
        _tag = [HZAdModel normalizeTag:tag];
        _retriesRemaining = kHZAdRetries;
        
        NSString *internetStatus = [HZUtils internetStatus];
        NSNumber *diskSpaceInBytes = [NSNumber numberWithUnsignedLongLong:[[HZDevice currentDevice] hzGetFreeDiskspace]];
        
        UIInterfaceOrientation deviceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        NSString *orientation = UIInterfaceOrientationIsLandscape(deviceOrientation) ? @"landscape" : @"portrait";
        
        // override
        if (fetchableCreativeType == HZFetchableCreativeTypeVideo) {
            orientation = @"landscape";
        }
        
        CGFloat statusBarHeight = 0;
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        screenSize = UIInterfaceOrientationIsLandscape(deviceOrientation) ?
        CGSizeMake(screenSize.height, screenSize.width) : CGSizeMake(screenSize.width, screenSize.height);
        
        NSString *deviceDPI = [NSString stringWithFormat: @"%f", [UIScreen mainScreen].scale];
        
        NSString *supportedFeatures = @"actions_from_webview,js_visibility_callback,chromeless";
        NSString *creativeTypesString = [[self class] creativeTypeStringForFetchableType:fetchableCreativeType];
        
        _generatedParams = [NSMutableDictionary dictionaryWithDictionary:@{@"orientation": orientation,
                                                                           @"device_width": @(screenSize.width),
                                                                           @"device_height": @(screenSize.height),
                                                                           @"status_bar_height":@(statusBarHeight),
                                                                           @"supported_features": supportedFeatures,
                                                                           @"connection_type": internetStatus,
                                                                           @"device_free_bytes": diskSpaceInBytes,
                                                                           @"device_dpi": deviceDPI,
                                                                           @"creative_type": creativeTypesString,
                                                                           @"tag": _tag,
                                                                           @"auction_type": NSStringFromHZAuctionType(auctionType),
                                                                           }];
        
        if ([NSLocale preferredLanguages] != nil && [[NSLocale preferredLanguages] count] > 0) {
            NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
            [_generatedParams setObject: language forKey: @"locale_lang"];
        }
        
        NSLocale *currentLocale = [NSLocale autoupdatingCurrentLocale];  // get the current locale.
        NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
        if (countryCode != nil) {
            [_generatedParams setObject: countryCode forKey: @"locale_country"];
        }
        
        if ([[HZAdsManager sharedManager] framework] != nil) {
            [_generatedParams setObject: [[HZAdsManager sharedManager] framework] forKey: @"sdk_framework"];
        }
        
        if ([[HZAdsManager sharedManager] mediator] != nil) {
            [_generatedParams setObject: [[HZAdsManager sharedManager] mediator] forKey: @"sdk_mediator"];
        }
        
        if ([[HZAdsManager sharedManager] isDebuggable]) {
            [_generatedParams setObject: @"true" forKey: @"debug"];
            [_generatedParams setObject: @"1" forKey: @"use_random_strategy_v2"];
        }
        
        [_generatedParams addEntriesFromDictionary: additionalParams];
        
        if (additionalParams[@"creative_id"]) {
            _skipCache = YES;
            _ignoreAlreadyInstalledGame = YES;
        }
    }
    
    return self;
}

- (NSDictionary *) createParams {
    NSMutableDictionary *params = [self.generatedParams mutableCopy];
    
    if (self.rejectedImpressionID != nil) {
        [params setObject: self.rejectedImpressionID forKey: @"rejected_impression_id"];
    }
    
    if (self.alreadyInstalledGame != nil) {
        [params setObject: self.alreadyInstalledGame forKey: @"already_installed_game"];
    }
    
    return params;
}

- (void) decrementTries {
    _retriesRemaining = self.retriesRemaining - 1;
}

- (BOOL) canRetry {
    return _retriesRemaining > 0;
}

+ (NSString *)creativeTypeStringForFetchableType:(HZFetchableCreativeType)fetchableCreativeType {
    switch (fetchableCreativeType) {
        case HZFetchableCreativeTypeStatic: {
            return @"full_screen_interstitial,interstitial";
        }
        case HZFetchableCreativeTypeVideo: {
            return @"interstitial_video,video";
        }
        case HZFetchableCreativeTypeNative: {
            return @"native";
        }
    }
}

@end
