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
#import "HZEnums.h"

#import "HZAdsAPIClient.h"
#import "HZUtils.h"
#import "HZNSURLUtils.h"

@interface HZAdModel()
@property (nonatomic) NSMutableDictionary *additionalEventParams;
@property (nonatomic) NSNumber *refreshTime;
@property (nonatomic) NSString *adStrategy;
@property (nonatomic) NSNumber *creativeID;
@property (nonatomic) NSDate *fetchDate;
@property (nonatomic) BOOL hideOnOrientationChange;

// iOS 8 Server Side Configurable Properties
@property (nonatomic) BOOL enable90DegreeTransform;

@end

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

- (instancetype) initWithDictionary: (NSDictionary *) dict adUnit:(NSString *)adUnit auctionType:(HZAuctionType)auctionType {
    self = [super init];
    if (self) {
        _adUnit = adUnit;
        _auctionType = auctionType;
        
        _impressionID = [HZDictionaryUtils hzObjectForKey: @"impression_id" ofClass: [NSString class] default: @"" withDict: dict];
        _promotedGamePackage = [HZDictionaryUtils hzObjectForKey: @"promoted_game_package" ofClass: [NSNumber class] default: @(0) withDict: dict];
        _creativeType = [HZDictionaryUtils hzObjectForKey: @"creative_type" ofClass: [NSString class] default: @"" withDict: dict];
        
        _clickURL = ({
            NSString *clickURLString = [HZDictionaryUtils hzObjectForKey: @"click_url" ofClass: [NSString class] default: @"" withDict: dict];
            NSString *noPlaceHolderURL = [HZNSURLUtils substituteGetParams:clickURLString impressionID:_impressionID];
            [NSURL URLWithString:noPlaceHolderURL];
        });
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
        
        
        _enable90DegreeTransform = [[HZDictionaryUtils hzObjectForKey:@"enable_90_degree_transform"
                                                              ofClass:[NSNumber class]
                                                              default:@(!hziOS8Plus())
                                                             withDict:dict] boolValue];
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
    
    NSMutableDictionary *params = [self paramsForEventCallback];
    
    [[HZAdsAPIClient sharedClient] POST:kHZRegisterClickEndpoint parameters:params success:^(HZAFHTTPRequestOperation *operation, id JSON) {
        if ([[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: @(0) withDict: JSON] intValue] == 200) {
            self.sentClick = YES;
            [HZLog debug: [NSString stringWithFormat: @"(CLICK) %@", self]];
        }
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(CLICK ERROR) %@ Error: %@", self, error]];
    }];
    
    return YES;
}

- (BOOL) onImpression {
    if (self.sentImpression) return false;

    
    NSMutableDictionary *params = [self paramsForEventCallback];
    
    [[HZAdsAPIClient sharedClient] POST:kHZRegisterImpressionEndpoint parameters:params success:^(HZAFHTTPRequestOperation *operation, id JSON) {
        if ([[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: @(0) withDict: JSON] intValue] == 200) {
            self.sentImpression = YES;
            [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION) %@", self]];
        }
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION ERROR) %@, Error: %@", self, error]];
    }];
    
    return YES;
}

- (Class) controller {
    return [HZAdInterstitialViewController class];
}

#pragma mark - Factory
+ (HZAdModel *) modelForResponse: (NSDictionary *) response adUnit:(NSString *)adUnit auctionType:(HZAuctionType)auctionType {
    NSString *creativeType = [HZDictionaryUtils hzObjectForKey: @"creative_type" ofClass: [NSString class] default: @"interstitial" withDict: response];
    
    if ([HZVideoAdModel isValidForCreativeType: creativeType]) {
        return [[HZVideoAdModel alloc] initWithDictionary: response adUnit:adUnit auctionType:auctionType];
    } else {
        return [[HZInterstitialAdModel alloc] initWithDictionary: response adUnit:adUnit auctionType:auctionType];
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

- (NSMutableDictionary *) paramsForEventCallback {
    
    NSDictionary *standardParams = @{@"impression_id": self.impressionID,
                                     @"promoted_game_package": self.promotedGamePackage,
                                     @"tag": [HZAdModel normalizeTag: self.tag]};
    
    if (self.additionalEventParams != nil) {
        [self.additionalEventParams addEntriesFromDictionary: standardParams];
        return self.additionalEventParams;
    }
    
    return [[NSMutableDictionary alloc] initWithDictionary: standardParams];
}

- (void) setEventCallbackParams: (NSMutableDictionary *) dict {
    self.additionalEventParams = dict;
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
