//
//  HZAdModel.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZAdModel.h"
#import "HZDictionaryUtils.h"
#import "HZInterstitialAdModel.h"
#import "HZVideoAdModel.h"
#import "HZLog.h"
#import "HZAdInterstitialViewController.h"
#import "HZDevice.h"
#import "HeyzapAds.h"

#import "HZAdsAPIClient.h"

@implementation HZAdModel

#pragma mark - Validity

+ (BOOL) isValidForCreativeType: (NSString *) creativeType {
    return YES;
}

+ (BOOL) isResponseValid:(NSDictionary *)response withError: (NSError**) error {
    if ([[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: @(0) withDict: response] intValue] != 200) {
        if (error != NULL) {
            *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.fetch" code: 10 userInfo: @{NSLocalizedDescriptionKey: @"Bad Response Status"}];
        }
        
        return NO;
    }
    
    if ([[HZDictionaryUtils hzObjectForKey: @"impression_id" ofClass: [NSString class] default: @"" withDict: response] isEqualToString: @""] == YES) {
        if (error != NULL) {
            *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.fetch" code: 10 userInfo: @{NSLocalizedDescriptionKey: @"Bad Impression ID"}];
        }
            
        return NO;
    }
    
    if ([[HZDictionaryUtils hzObjectForKey: @"promoted_game_package" ofClass: [NSNumber class] default: @(0) withDict: response] intValue] == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.fetch" code: 10 userInfo: @{NSLocalizedDescriptionKey: @"Bad Promoted Package"}];
        }
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Initializers

- (id) initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        
        
        _impressionID = [HZDictionaryUtils hzObjectForKey: @"impression_id" ofClass: [NSString class] default: @"" withDict: dict];
        _promotedGamePackage = [HZDictionaryUtils hzObjectForKey: @"promoted_game_package" ofClass: [NSNumber class] default: @(0) withDict: dict];
        _creativeType = [HZDictionaryUtils hzObjectForKey: @"creative_type" ofClass: [NSString class] default: @"" withDict: dict];
        _clickURL = [NSURL URLWithString: [self substituteGetParams:[HZDictionaryUtils hzObjectForKey: @"click_url" ofClass: [NSString class] default: @"" withDict: dict]]];
        _refreshTime = [HZDictionaryUtils hzObjectForKey: @"refresh_time" ofClass: [NSNumber class] default: @(0) withDict: dict];
        _adStrategy = [HZDictionaryUtils hzObjectForKey: @"ad_strategy" ofClass: [NSString class] default: @"" withDict: dict];
        _creativeID = [HZDictionaryUtils hzObjectForKey: @"creative_id" ofClass: [NSNumber class] default: @(0) withDict: dict];
        _launchURI = [NSURL URLWithString: [HZDictionaryUtils hzObjectForKey: @"launch_uri" ofClass: [NSString class] default: @"" withDict: dict]];
        NSNumber *useSKStoreProduct = [HZDictionaryUtils hzObjectForKey: @"use_modal_app_store" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO] withDict: dict];
        _useModalAppStore = useSKStoreProduct ? [useSKStoreProduct boolValue] : YES; // default to YES
        _hideOnOrientationChange = [[HZDictionaryUtils hzObjectForKey:@"hide_on_orientation_change" ofClass:[NSNumber class] default: @(1) withDict: dict] boolValue];
        
        NSString *requiredOrientation = [HZDictionaryUtils hzObjectForKey: @"required_orientation" ofClass: [NSString class] default: @"portrait" withDict: dict];
        if ([requiredOrientation isEqualToString: @"portrait"]) {
            _requiredAdOrientation = UIInterfaceOrientationMaskPortrait;
        } else {
            _requiredAdOrientation = UIInterfaceOrientationMaskLandscape;
        }

        _sentClick = NO;
        _sentImpression = NO;
        _sentIncentiveComplete = NO;
        _fetchDate = [NSDate date];
    }
    
    return self;
}


- (NSString *) description {
    return [NSString stringWithFormat: @"<%@ I:%@ A:%@ T:%@ PKG: %@>", [self class], _impressionID, _adUnit, _tag, _promotedGamePackage];
}

#pragma mark - Expiry
- (BOOL) isExpired {
    int refreshTime = [self.refreshTime intValue];
    if (refreshTime > 0 && [self.fetchDate timeIntervalSinceNow] > refreshTime) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Attribution Events
- (BOOL) isInstalled {
    return [[UIApplication sharedApplication] canOpenURL: self.launchURI];
}

- (BOOL) onClick {
    if (self.sentClick) return false;
    
    NSDictionary *params = @{@"impression_id": self.impressionID,
                             @"promoted_game_package": self.promotedGamePackage,
                             @"tag": self.tag};
    
    [[HZAdsAPIClient sharedClient] post: @"register_click" withParams: params success:^(id JSON) {
        if ([[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: @(0) withDict: JSON] intValue] == 200) {
            self.sentClick = YES;
            [HZLog debug: [NSString stringWithFormat: @"(CLICK) %@", self]];
        }
    } failure:^(NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(CLICK ERROR) %@ Error: %@", self, error]];
    }];
    
    return YES;
}

- (BOOL) onImpression {
    if (self.sentImpression) return false;

    NSDictionary *params = @{@"impression_id": self.impressionID,
                             @"promoted_game_pacakge": self.promotedGamePackage,
                             @"tag": self.tag};
    
    [[HZAdsAPIClient sharedClient] post: @"register_impression" withParams: params success:^(id JSON) {
        if ([[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: @(0) withDict: JSON] intValue] == 200) {
            self.sentImpression = YES;
            [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION) %@", self]];
        }
    } failure:^(NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION ERROR) %@, Error: %@", self, error]];
    }];
    
    return YES;
}

- (BOOL) onIncentiveComplete {
    if (self.sentIncentiveComplete) {
        NSDictionary *params = @{@"impression_id": self.impressionID,
                                 @"promoted_game_pacakge": self.promotedGamePackage,
                                 @"tag": self.tag};
        
        [[HZAdsAPIClient sharedClient] post: @"register_incentive_complete" withParams: params success:^(id JSON) {
            if ([[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: @(0) withDict: JSON] intValue] == 200) {
                self.sentIncentiveComplete = YES;
                [HZLog debug: [NSString stringWithFormat: @"(INCENTIVE COMPLETE) %@", self]];
            }
        } failure:^(NSError *error) {
            [HZLog debug: [NSString stringWithFormat: @"(INCENTIVE COMPLETE ERROR) %@, Error: %@", self, error]];
        }];
    }
    
    return YES;
}

- (Class) controller {
    return [HZAdInterstitialViewController class];
}

#pragma mark - Factory
+ (HZAdModel *) modelForResponse: (NSDictionary *) response {
    NSString *creativeType = [HZDictionaryUtils hzObjectForKey: @"creative_type" ofClass: [NSString class] default: @"interstitial" withDict: response];
    
    if ([HZVideoAdModel isValidForCreativeType: creativeType]) {
        return [[HZVideoAdModel alloc] initWithDictionary: response];
    } else {
        return [[HZInterstitialAdModel alloc] initWithDictionary: response];
    }
    
    return nil;
}

- (void) cleanup {
    
}

// Do not reference super if overriding
- (void) doPostFetchActionsWithCompletion: (void (^)(BOOL result))completion {
    if (completion) {
        completion(YES);
    }
}

- (NSString *)substituteGetParams:(NSString *)url {
    NSString *result = [url stringByReplacingOccurrencesOfString:@"{MAC_ADDRESS_MD5}" withString:[[HZDevice currentDevice] HZmd5MacAddress]];
    result = [result stringByReplacingOccurrencesOfString:@"{MAC_ADDRESS}" withString:[[HZDevice currentDevice] HZmacaddress]];
    result = [result stringByReplacingOccurrencesOfString:@"{IDFA}" withString:[[HZDevice currentDevice] HZadvertisingIdentifier]];
    result = [result stringByReplacingOccurrencesOfString:@"{IMPRESSION_ID}" withString:self.impressionID];
    result = [result stringByReplacingOccurrencesOfString:@"{ODIN}" withString:[[HZDevice currentDevice] HZODIN1]];
    result = [result stringByReplacingOccurrencesOfString: @"{UDID}" withString: @""]; //Deprecated
    result = [result stringByReplacingOccurrencesOfString: @"{OPEN_UDID}" withString: [[HZDevice currentDevice] HZOpenUDID]];
    result = [result stringByReplacingOccurrencesOfString: @"{IDFV}" withString: [[HZDevice currentDevice] HZvendorDeviceIdentity]];
    
    return result;
}

+ (NSString *) normalizeTag:(NSString *)tag {
    if (tag != nil) {
        tag = [tag stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    if (tag == nil || [tag isEqualToString: @""]) {
        tag = [HeyzapAds defaultTagName];
    }
    
    return [tag stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];;
}

@end
