//
//  HZAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 5/2/13.
//
//

#import "HZAd.h"

#import "HZAdsController.h"
#import "UIDevice+HZIdentifierAddition.h"

#import "NSDictionary+HZClassChecking.h"
#import "HZAdsAPIClient.h"
#import "HZLog.h"
#import "HZAdsManager.h"
#import "HZUtils.h"

#define FETCH_ENDPOINT @"in_game_api/ads/fetch_ad"

@interface HZAd()

@property (nonatomic) BOOL hideOnOrientationChange;
@property (nonatomic) HZAdOrientation requiredAdOrientation;
@property (nonatomic) BOOL showBlackBackground;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic) BOOL disableScroll;
@property (strong, nonatomic) NSDate *fetchedAt;
@property (nonatomic) NSTimeInterval expireAfter;

@property (nonatomic) BOOL fillParentHeight;
@property (nonatomic) BOOL fillParentWidth;
@property (nonatomic) HZAdAnimationType animationType;
@property (nonatomic) BOOL useSKStoreProductViewController;

@end

@implementation HZAd{}

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.html = [dict objectForKey:@"ad_html"];
        self.strategy = [dict objectForKey:@"ad_strategy"];
        self.promotedGame = [dict hzObjectForKey: @"promoted_game_package" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 0]];
        self.impressionId = [dict objectForKey:@"impression_id"];
        self.expireAfter = [[dict hzObjectForKey:@"refresh_time" ofClass:[NSNumber class]] doubleValue];
        if (self.expireAfter <= 0) {
            //DLog(@"Warning -- ad expiry was <= 0; it needs to be set from the server. Defaulting to 1 day");
            self.expireAfter = 86400; //day
        }
        self.fetchedAt = [NSDate date];
        
        _hideOnOrientationChange = [[dict hzObjectForKey:@"hide_on_orientation_change" ofClass:[NSNumber class]] boolValue];
        _requiredAdOrientation = hzAdOrientationFromString([dict hzObjectForKey:@"required_orientation" ofClass:[NSString class]]);
        _showBlackBackground = [[dict hzObjectForKey:@"background_overlay" ofClass:[NSNumber class]] boolValue];
        
        
        _disableScroll = [[dict hzObjectForKey:@"disable_scroll" ofClass:[NSNumber class]] boolValue]; // (Defaults to scrolling)
        
        NSNumber *useSKStoreProduct = [dict hzObjectForKey: @"use_modal_app_store" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO]];
        _useSKStoreProductViewController = useSKStoreProduct ? [useSKStoreProduct boolValue] : YES; // default to YES
#if DEBUG
        _useSKStoreProductViewController = YES; // Don't know if it's possible to get back to the app after going to the app store when doing integration testing.
#endif
        
        _animationType = hzAdAnimationTypeFromString([dict hzObjectForKey:@"animation_type" ofClass:[NSString class]]);
        
        NSString *launchString = [dict hzObjectForKey:@"launch_uri" ofClass:[NSString class]];
        if (launchString) {
            if ([launchString rangeOfString:@"://"].location == NSNotFound) {
                launchString = [launchString stringByAppendingString:@"://"];
            }
            _launchURI = [NSURL URLWithString:launchString];
        }
                                  
        NSArray *dimensions = [dict hzObjectForKey:@"ad_dimensions" ofClass:[NSArray class]]; // Old model.
        id adHeight = [dict objectForKey:@"ad_height"];
        id adWidth = [dict objectForKey:@"ad_width"];

        if (adHeight && adWidth) {

            CGFloat height = 0;

            if (![adHeight isKindOfClass: [NSNull class]]) {
                if ([adHeight isKindOfClass:[NSString class]] && [adHeight isEqualToString:@"fill_parent"]) {
                    self.fillParentHeight = YES;
                    self.isFullScreen = YES;
                } else if ([adHeight respondsToSelector:@selector(floatValue)]) {
                    height = [adHeight floatValue];
                }
            }
            
            CGFloat width = 0;
            
            if (![adWidth isKindOfClass: [NSNull class]]) {
                if ([adWidth isKindOfClass:[NSString class]] && [adWidth isEqualToString:@"fill_parent"]) {
                    self.fillParentWidth = YES;
                    self.isFullScreen = YES;
                } else if ([adWidth respondsToSelector:@selector(floatValue)]) {
                    width = [adWidth floatValue];
                }
            }
            
            self.dimensions = CGSizeMake(width, height);
        } else {
            if ([dimensions count] == 2) {
                self.dimensions = CGSizeMake([[dimensions objectAtIndex:0] floatValue], [[dimensions objectAtIndex:1] floatValue]);
            } else {
                self.dimensions = CGSizeMake(0, 0);
            }
        }
        
        
        if (self.dimensions.width == 0 || self.dimensions.height == 0 || self.dimensions.width == NAN || self.dimensions.height == NAN) {
            //DLog(@"One of the dimensions was 0 or NaN; returning nil");
            //DLog(@"Dict = %@",dict);
            return nil;
        }
        
        
        NSString *url = [dict objectForKey:@"click_url"];        
        if (url) {
            self.clickURL = [NSURL URLWithString: [self substituteGetParams:url]];
        }
    }
    
    if (!self.isValid) {
        //DLog(@"Invalid");
        //DLog(@"ad = %@",self);
        return nil;
    }
    
    return self;
}

NSString * const kHZRefetchCountKey = @"kHZRefetchCountKey";
NSString * const kHZAdsSDKError = @"com.heyzap.sdk.ads";

#pragma mark - Static

+ (void) fetchWithTag: (NSString *) tag andOptionalParams: (NSDictionary *) optionalParams andCompletion: (void (^)(NSString *tagName, BOOL fetched, NSError *error)) completion {
    
    HZAd *ad = [[HZAdsManager sharedManager] adForTag: tag];
    const BOOL specifiedCreative = [optionalParams objectForKey:@"creative_id"] || [optionalParams objectForKey:@"random_creative_with_type"]; // Don't cache for this scenario
    if (ad != nil && [ad isValid] && (hzCurrentScreenOrientation() == ad.requiredAdOrientation) && !specifiedCreative) {
        if (completion) {
            completion(tag, NO, nil);
        }
        
        return;
    }
    
    if (![[UIDevice currentDevice] hzHasInternetConnection]) {
        [HZLog debug:@"No internet -- not prefetching"];
        if (completion) {
            completion(tag, NO, [NSError errorWithDomain: kHZAdsSDKError code: 1 userInfo: @{NSLocalizedDescriptionKey: @"No internet connection."}]);
        }
    }
    
    NSString *orientation = NSStringFromHZAdOrientation(hzCurrentScreenOrientation());
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    if (hzCurrentScreenOrientation() == HZAdOrientationLandscape) {
        screenSize = CGSizeMake(screenSize.height, screenSize.width);
    } else if (hzCurrentScreenOrientation() == HZAdOrientationPortrait) {
        screenSize = CGSizeMake(screenSize.width, screenSize.height);
    }
    
    NSString *internetStatus = [[UIDevice currentDevice] HZConnectivityType] ?: @"no_internet";
    NSArray *availableAnimations = hzAdAnimationAvailableAnimations();
    NSNumber *diskSpaceInBytes = [NSNumber numberWithUnsignedLongLong:[[UIDevice currentDevice] hzGetFreeDiskspace]];
    
    if (![HZUtils appID]) {
        if (completion) {
            completion(tag, NO, [NSError errorWithDomain: kHZAdsSDKError code: 0 userInfo: @{NSLocalizedDescriptionKey: @"Invalid App ID"}]);
        }
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                   @"orientation": orientation,
                                   @"app_store_id": [HZUtils appID],
                                   @"creative_type": [@[@"interstitial", @"full_screen_interstitial"] componentsJoinedByString:@","],
                                   @"device_width": @(screenSize.width),
                                   @"device_height": @(screenSize.height),
                                   @"status_bar_height":@([HZAdsController logicalStatusBarHeight]),
                                   @"fullscreen_ad":@YES,
                                   @"supported_features": @[@"actions_from_webview",@"js_visibility_callback"],
                                   @"available_animations": availableAnimations,
                                   @"internet_status": internetStatus,
                                   @"disk_space_in_bytes": diskSpaceInBytes
                                   }];
    
    if (tag && ![tag isEqualToString: @""]) {
        [params setObject: tag forKey: @"tag"];
    }
    
    if ([[HZAdsManager sharedManager] isDebug]) {
        [params addEntriesFromDictionary:@{@"use_random_strategy_v2" : @YES}];
    }
    
    if (optionalParams != nil) {
        [params addEntriesFromDictionary:optionalParams];
    }
    
    [[HZAdsAPIClient sharedClient] post: FETCH_ENDPOINT
                          withParams: params
                             success:^(id JSON) {
                                HZAd *fetchedAd = [[HZAd alloc] initWithDictionary:JSON];
                                fetchedAd.tagName = tag;
                                
                                if ([fetchedAd isInstalled]) {

                                    if ([optionalParams[kHZRefetchCountKey] intValue] >= 1) { // (means we allow for 2 failed fetches)
                                        
                                        // Since we're not refetching, tell the server that we've already installed.
                                        [[HZAdsAPIClient sharedClient] post:@"in_game_api/ads/add_initial_packages"
                                                                 withParams:@{@"app_store_ids": fetchedAd.promotedGame} // comma separared list format
                                                                    success:nil
                                                                    failure:nil];
                                        if (completion) {
                                            completion(tag,NO,[NSError errorWithDomain:kHZAdsSDKError code:2 userInfo:@{NSLocalizedDescriptionKey: @"Reached the maximum number of fetch retries."}]);
                                        }
                                        
                                    } else {
                                        NSMutableDictionary *refetchParams = [[NSMutableDictionary alloc] initWithDictionary:optionalParams];
                                        refetchParams[@"already_installed_game"] = fetchedAd.promotedGame;
                                        refetchParams[kHZRefetchCountKey] = @([refetchParams[kHZRefetchCountKey] intValue] + 1);
                                        
                                        [self fetchWithTag: tag andOptionalParams: refetchParams andCompletion: completion];
                                    }
                                    
                                } else if ([fetchedAd isValid]) {
                                    [[HZAdsManager sharedManager] addAd: fetchedAd];
                                    if (completion) {
                                        completion(tag, YES, nil);
                                    }
                                    
                                } else {
                                    if (completion) {
                                        NSError *error = [NSError errorWithDomain: kHZAdsSDKError code: 5 userInfo: @{NSLocalizedDescriptionKey: @"Failed to fetch a valid ad."}];
                                        completion(tag, YES, error);
                                    }
                                }
                            }
     
                            failure:^(NSError *error){
                                //DLog(@"Network error; error = %@",error);
                                if (completion) {
                                    completion(tag, YES, error);
                                }
                            }];

    
}

#pragma mark - Ad Lifecycle

- (void) onClick {
    
    NSDictionary *params = @{@"promoted_game_package": self.promotedGame,
                             @"ad_strategy": self.strategy,
                             @"impression_id": self.impressionId};
    
    NSString *endpoint = @"in_game_api/ads/register_click";
    
    [[HZAdsAPIClient sharedClient] post: endpoint
                          withParams: params
                                success: ^(NSDictionary  *JSON) {
                                    NSNumber *status = [JSON hzObjectForKey: @"status" ofClass: [NSNumber class] default: @0];
                                    if ([status intValue] != 200) {
                                        [HZLog debug: [NSString stringWithFormat: @"(CLICK) FAILED: %@", self.impressionId]];
                                    }
                                }
                                failure: ^(NSError *error) {
                                    [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION) FAILED: %@", self.impressionId]];
                                }];
}

- (void) onImpression {
    NSDictionary *params = @{
                        @"promoted_game_package": self.promotedGame,
                        @"impression_id": self.impressionId,
                        @"ad_tag":self.tagName};
    
    NSString *endpoint = @"in_game_api/ads/register_impression";
    
    //register the impression and show ad
    [[HZAdsAPIClient sharedClient] post: endpoint
                          withParams: params
                                success: ^(NSDictionary  *JSON) {
                                    NSNumber *status = [JSON hzObjectForKey: @"status" ofClass: [NSNumber class] default: @0];
                                    if ([status intValue] != 200) {
                                        [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION) FAILED: %@", self.impressionId]];
                                    }
                                }
                                failure: ^(NSError *error) {
                                    [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION) FAILED: %@", self.impressionId]];
                                }];
}

#pragma mark - Setters/Getters

// If we're set to fill parent width, dynamically determine the size
// This means we still show a fullscreen ad even if the status bar changed height.
- (CGSize)dimensions
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    CGFloat width = _dimensions.width;
    if (self.fillParentWidth) {
        width = screenSize.width;
        if (self.requiredAdOrientation == HZAdOrientationLandscape) {
            width -= [HZAdsController logicalStatusBarHeight];
        }
    }
    
    CGFloat height = _dimensions.height;
    if (self.fillParentHeight) {
        height = screenSize.height;
        if (self.requiredAdOrientation == HZAdOrientationPortrait) {
            height -= [HZAdsController logicalStatusBarHeight];
        }
    }
    
    return CGSizeMake(width, height);
}

- (BOOL)isValid {
    return self.html && self.strategy && self.promotedGame && [self.promotedGame intValue] > 0 && self.clickURL && self.impressionId && self.dimensions.width > 0 && self.dimensions.height > 0;
}

- (BOOL)isExpired {
    return [[NSDate date] timeIntervalSinceDate:self.fetchedAt] >= self.expireAfter;
}

- (BOOL)isInstalled {
    if (!self.launchURI) {
        return NO;
    }
    return [[UIApplication sharedApplication] canOpenURL:self.launchURI];
}

#pragma mark - Misc. Utility

- (NSString *)substituteGetParams:(NSString *)url {
    NSString *result = [url stringByReplacingOccurrencesOfString:@"{MAC_ADDRESS_MD5}" withString:[[UIDevice currentDevice] HZmd5MacAddress]];
    result = [result stringByReplacingOccurrencesOfString:@"{MAC_ADDRESS}" withString:[[UIDevice currentDevice] HZmacaddress]];
    result = [result stringByReplacingOccurrencesOfString:@"{IDFA}" withString:[[UIDevice currentDevice] HZadvertisingIdentifier]];
    result = [result stringByReplacingOccurrencesOfString:@"{IMPRESSION_ID}" withString:self.impressionId];
    result = [result stringByReplacingOccurrencesOfString:@"{ODIN}" withString:[[UIDevice currentDevice] HZODIN1]];
    result = [result stringByReplacingOccurrencesOfString: @"{UDID}" withString: @""]; //Deprecated
    
    return result;
}

- (NSString *)description
{
    NSMutableString *description = [@"" mutableCopy];
    [description appendFormat:@"HTML: %@\n",self.html];
    [description appendFormat:@"Strategy: %@\n",self.strategy];
    [description appendFormat:@"Promoted: %@\n",self.promotedGame];
    [description appendFormat:@"ClickURL: %@\n",self.clickURL];
    [description appendFormat:@"ImpressionId: %@\n",self.impressionId];
    [description appendFormat:@"Size: %@\n",NSStringFromCGSize(self.dimensions)];
    [description appendFormat:@"Valid: %i\n",[self isValid]];
    return description;
}

#pragma mark



#pragma mark - Enum Support

HZAdOrientation hzCurrentScreenOrientation(void)
{
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return HZAdOrientationPortrait;
    }
    return HZAdOrientationLandscape;
}

NSString * const kHZAdOrientationPortraitString = @"portrait";
NSString * const kHZAdOrientationLandscapeString = @"landscape";

HZAdOrientation hzAdOrientationFromString(NSString *adOrientationString)
{
    if ([adOrientationString isEqualToString:kHZAdOrientationPortraitString]) {
        return HZAdOrientationPortrait;
    } else {
        return HZAdOrientationLandscape;
    }
}

NSString *NSStringFromHZAdOrientation(HZAdOrientation orientation)
{
    if (orientation == HZAdOrientationPortrait) {
        return kHZAdOrientationPortraitString;
    } else {
        return kHZAdOrientationLandscapeString;
    }
}

HZAdAnimationType hzAdAnimationTypeFromString(NSString *animationType) {
    if ([animationType isEqualToString:@"animation_type_scale_up"]) {
        return HZAdAnimationTypeScaleUp;
    }
    
    return HZAdAnimationTypeNone;
}

NSString *NSStringFromHZAdAnimationType(HZAdAnimationType type)
{
    switch (type) {
        case HZAdAnimationTypeNone: {
            return @"animation_type_none";
            break;
        }
        case HZAdAnimationTypeScaleUp: {
            return @"animation_type_scale_up";
            break;
        }
    }
}

NSArray *hzAdAnimationAvailableAnimations(void)
{
    return @[ NSStringFromHZAdAnimationType(HZAdAnimationTypeNone),
              NSStringFromHZAdAnimationType(HZAdAnimationTypeScaleUp), ];
}

@end
