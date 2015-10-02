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
@property (nonatomic) NSMutableDictionary<NSString *, id> *additionalEventParams;
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

- (HZCreativeType)showableCreativeType {
    HZAssert(_showableCreativeType != HZCreativeTypeUnknown, @"[Heyzap internal ad network] The showableCreativeType has not been set");
    return _showableCreativeType;
}

- (HZAdType)requestingAdType {
    HZAssert(_requestingAdType != 0, @"Requesting ad type asked for before it's been set.");
    return _requestingAdType;
}

+ (BOOL) isValidForCreativeType: (NSString *) creativeType {
    return YES;
}

+ (BOOL) isResponseValid:(NSDictionary *)response withError: (NSError**) error {
    if ([[HZDictionaryUtils objectForKey: @"status" ofClass: [NSNumber class] default: @0 dict: response] intValue] != 200) {
        if (error != NULL) {
            *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.fetch" code: 10 userInfo: @{NSLocalizedDescriptionKey: @"Bad Response Status"}];
        }
        
        return NO;
    }
    
    if ([[HZDictionaryUtils objectForKey: @"impression_id" ofClass: [NSString class] default: @"" dict: response] isEqualToString: @""] == YES) {
        if (error != NULL) {
            *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.fetch" code: 10 userInfo: @{NSLocalizedDescriptionKey: @"Bad Impression ID"}];
        }
            
        return NO;
    }
    
    if ([[HZDictionaryUtils objectForKey: @"promoted_game_package" ofClass: [NSNumber class] default: @0 dict: response] intValue] == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.fetch" code: 10 userInfo: @{NSLocalizedDescriptionKey: @"Bad Promoted Package"}];
        }
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Initializers

- (instancetype) initWithDictionary: (NSDictionary *) dict fetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType {
    self = [super init];
    if (self) {
        _fetchableCreativeType = fetchableCreativeType;
        _auctionType = auctionType;
        
        _impressionID = [HZDictionaryUtils objectForKey: @"impression_id" ofClass: [NSString class] default: @"" dict: dict];
        _promotedGamePackage = [HZDictionaryUtils objectForKey: @"promoted_game_package" ofClass: [NSNumber class] default: @0 dict: dict];
        _creativeType = [HZDictionaryUtils objectForKey: @"creative_type" ofClass: [NSString class] default: @"" dict: dict];
        
        _clickURL = ({
            NSString *clickURLString = [HZDictionaryUtils objectForKey: @"click_url" ofClass: [NSString class] default: @"" dict: dict];
            NSString *noPlaceHolderURL = [HZNSURLUtils substituteGetParams:clickURLString impressionID:_impressionID];
            [NSURL URLWithString:noPlaceHolderURL];
        });
        _refreshTime = [HZDictionaryUtils objectForKey: @"refresh_time" ofClass: [NSNumber class] default: @0 dict: dict];
        _adStrategy = [HZDictionaryUtils objectForKey: @"ad_strategy" ofClass: [NSString class] default: @"" dict: dict];
        _creativeID = [HZDictionaryUtils objectForKey: @"creative_id" ofClass: [NSNumber class] default: @0 dict: dict];
        _launchURI = [NSURL URLWithString: [HZDictionaryUtils objectForKey: @"launch_uri" ofClass: [NSString class] default: @"" dict: dict]];
        NSNumber *useSKStoreProduct = [HZDictionaryUtils objectForKey: @"use_modal_app_store" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO] dict: dict];
        _useModalAppStore = useSKStoreProduct ? [useSKStoreProduct boolValue] : YES; // default to YES
        _hideOnOrientationChange = [[HZDictionaryUtils objectForKey:@"hide_on_orientation_change" ofClass:[NSNumber class] default: @1 dict: dict] boolValue];
        
        NSString *requiredOrientation = [HZDictionaryUtils objectForKey: @"required_orientation" ofClass: [NSString class] default: @"portrait" dict: dict];
        if ([requiredOrientation isEqualToString: @"portrait"]) {
            _requiredAdOrientation = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
        } else {
            _requiredAdOrientation = UIInterfaceOrientationMaskLandscape;
        }
        
        _sentClick = NO;
        _sentImpression = NO;
        _sentIncentiveComplete = NO;
        _fetchDate = [NSDate date];
        
        
        _enable90DegreeTransform = [[HZDictionaryUtils objectForKey:@"enable_90_degree_transform"
                                                              ofClass:[NSNumber class]
                                                              default:@(!hziOS8Plus())
                                                             dict:dict] boolValue];
    }
    
    return self;
}



- (NSString *) description {
    return [NSString stringWithFormat: @"<%@ I:%@ creativeType:%@ T:%@ PKG: %@>", [self class], _impressionID, NSStringFromHZFetchableCreativeType(self.fetchableCreativeType), _tag, _promotedGamePackage];
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
    return [HZDevice canCheckURLSchemes] && [[UIApplication sharedApplication] canOpenURL: self.launchURI];
}

- (BOOL) onClick {
    if (self.sentClick) return NO;
    
    NSMutableDictionary *params = [self paramsForEventCallback];
    
    [[HZAdsAPIClient sharedClient] POST:kHZRegisterClickEndpoint parameters:params success:^(HZAFHTTPRequestOperation *operation, id JSON) {
        if ([[HZDictionaryUtils objectForKey: @"status" ofClass: [NSNumber class] default: @0 dict: JSON] intValue] == 200) {
            self.sentClick = YES;
            [HZLog debug: [NSString stringWithFormat: @"(CLICK) %@", self]];
        }
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(CLICK ERROR) %@ Error: %@", self, error]];
    }];
    
    return YES;
}

- (BOOL) onImpression {
    if (self.sentImpression) return NO;

    
    NSMutableDictionary *params = [self paramsForEventCallback];
    
    [[HZAdsAPIClient sharedClient] POST:kHZRegisterImpressionEndpoint parameters:params success:^(HZAFHTTPRequestOperation *operation, id JSON) {
        if ([[HZDictionaryUtils objectForKey: @"status" ofClass: [NSNumber class] default: @0 dict: JSON] intValue] == 200) {
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
+ (HZAdModel *) modelForResponse: (NSDictionary *) response fetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType {
    
    switch (fetchableCreativeType) {
        case HZFetchableCreativeTypeStatic: {
            return [[HZInterstitialAdModel alloc] initWithDictionary:response fetchableCreativeType:fetchableCreativeType auctionType:auctionType];
        }
        case HZFetchableCreativeTypeVideo: {
            return [[HZVideoAdModel alloc] initWithDictionary:response fetchableCreativeType:fetchableCreativeType auctionType:auctionType];
        }
        case HZFetchableCreativeTypeNative: {
            HZELog(@"Native is not a valid creative for HZAdModel");
            return nil;
        }
    }
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
                                     @"tag": [HZAdModel normalizeTag: self.tag],
                                     @"ad_unit":NSStringFromAdType(self.requestingAdType),
                                     };
    
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
        tag = [[HeyzapAds defaultTagName] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    return [tag lowercaseString];
}

@end
