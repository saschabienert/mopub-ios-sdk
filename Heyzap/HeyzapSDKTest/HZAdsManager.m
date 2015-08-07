//
//  HZAdsManager.m
//  Heyzap
//
//  Created by Daniel Rhodes on 8/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdsManager.h"
#import "HZAPIClient.h"
#import "HZUserDefaults.h"
#import "HZUtils.h"
#import "HZAdsAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZAdModel.h"
#import "HZDevice.h"
#import "HZAdLibrary.h"
#import "HZAdVideoViewController.h"
#import "HZAdInterstitialViewController.h"
#import "HeyzapAds.h"
#import "HZDelegateProxy.h"
#import "HZEnums.h"

#import "HZDelegateProxy.h"
#import "HZWebViewPool.h"
#import "HZDownloadHelper.h"
#import "HZNSURLUtils.h"
#import "HZPaymentTransactionObserver.h"

#define HAS_REPORTED_INSTALL_KEY @"hz_install_reported"
#define DEFAULT_RETRIES 3

#define UNITY_FRAMEWORK @"unity3d"
#define AIR_FRAMEWORK @"air"

@interface HZAdsManager()
@property (nonatomic, strong) HZDelegateProxy *interstitialDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *incentivizedDelegateProxy;
@property (nonatomic, strong) HZDelegateProxy *videoDelegateProxy;
@end

@implementation HZAdsManager

static BOOL hzAdsIsEnabled = NO;

- (id) init {
    self = [super init];
    if (self) {
        hzAdsIsEnabled = YES;
        _interstitialDelegateProxy = [[HZDelegateProxy alloc] init];
        _incentivizedDelegateProxy = [[HZDelegateProxy alloc] init];
        _videoDelegateProxy = [[HZDelegateProxy alloc] init];

        [[self class] runInitialTasks];
    }
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Run Initial Tasks

- (void) onStart {
    if (![self isOptionEnabled:HZAdOptionsDisableAutomaticIAPRecording]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:[HZPaymentTransactionObserver sharedInstance]];
    }
}

+ (void) runInitialTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [HZDownloadHelper clearCache];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            //register this game as installed, if we haven't done so already
            if (![[HZUserDefaults sharedDefaults] objectForKey:HAS_REPORTED_INSTALL_KEY]) {
                [[HZAdsAPIClient sharedClient] POST:@"register_new_game_install" parameters:@{} success:^(HZAFHTTPRequestOperation *operation, id JSON) {
                    [[HZUserDefaults sharedDefaults] setObject:@YES forKey:HAS_REPORTED_INSTALL_KEY];
                } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                    HZDLog(@"Error reporting new game install = %@",error);
                }];
            }
        });
    });
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [HZNSURLUtils substituteGetParams:@"" impressionID:@""];
        [[HZDevice currentDevice] hzGetFreeDiskspace];
    });
    
    [[HZWebViewPool sharedPool] seedWithPools:2];
    
    
    [self reportInstalledGames];
}

+ (void)reportInstalledGames
{
    // There are some frightening reports of the `canOpenURL:` method being really slow on iOS 7 devices with a SIM card. I wasn't able to replicate this on my 5S running 7.0.3, and even based on the person reporting 1700 URLs taking 22 seconds to check, we should take < 1 second, so I'm figuring we'll be ok.
    // http://vntin.com/openradar.appspot.com/15020847 https://github.com/danielamitay/iHasApp/issues/16 https://twitter.com/agiletortoise/status/371650061416931329
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString * const dateOfCheckKey = @"dateOfCheckingInstalledGames";
        NSDate *date = [[HZUserDefaults sharedDefaults] objectForKey:dateOfCheckKey];
        const NSTimeInterval oneWeek = 604800;
        if (date && [[NSDate date] timeIntervalSinceDate:date] < oneWeek) {
            return;
        }
        
        [[HZAdsAPIClient sharedClient] GET:@"games_to_check.json" parameters:nil success:^(HZAFHTTPRequestOperation *operation, NSArray *response) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                NSMutableArray *installedGames = [@[] mutableCopy];
                for (NSDictionary *game in response) {
                    NSNumber *const gameID = [HZDictionaryUtils objectForKey:@"game_id" ofClass:[NSNumber class] dict: game];
                    
                    NSURL *const launchURL = ({
                        NSString *launchString = [HZDictionaryUtils objectForKey:@"launch_uri" ofClass:[NSString class] dict: game];
                        if ([launchString rangeOfString:@"://"].location == NSNotFound) {
                            launchString = [launchString stringByAppendingString:@"://"];
                        }
                        [NSURL URLWithString:launchString];
                    });
                    
                    if (gameID == nil || launchURL == nil) {
                        continue;
                    }
                    
                    if ([[UIApplication sharedApplication] canOpenURL:launchURL]) {
                        [installedGames addObject:gameID];
                    }
                }
                
                [[HZAdsAPIClient sharedClient] POST:@"add_initial_packages" parameters:@{@"installed_game_ids": installedGames} success:^(HZAFHTTPRequestOperation *operation, id responseObject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                        [[HZUserDefaults sharedDefaults] setObject:[NSDate date] forKey:dateOfCheckKey];
                    });
                } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                    HZDLog(@"Error adding_initial_packages = %@",error);
                }];
            });
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            HZDLog(@"Error getting games = %@",error);
        }];
    });
}

#pragma mark - Getters/Setters

- (void) setPublisherID:(NSString *)publisherID {
    _publisherID = publisherID;
    [HZUtils setPublisherID: publisherID];
}

#pragma mark - Enabled

+ (BOOL) isEnabled {
    return hzAdsIsEnabled;
}

+ (BOOL) isVersionSupported {
    return ![HZDevice hzSystemVersionIsLessThan:@"6.0"];
}

- (BOOL)isAdobeAir {
    return [self.framework isEqualToString:AIR_FRAMEWORK];
}

- (BOOL)isUnity3D {
    return [self.framework isEqualToString:UNITY_FRAMEWORK];
}

#pragma mark - Is Available

- (BOOL)isAvailableForAdUnit:(NSString *)adUnit auctionType:(HZAuctionType)auctionType
{
    return [[HZAdLibrary sharedLibrary] peekAtAdForAdUnit:adUnit auctionType:auctionType] != nil;
}

#pragma mark - Show

- (void) showForAdUnit: (NSString *) adUnit auctionType:(HZAuctionType)auctionType options:(HZShowOptions *)options  {
    BOOL result = NO;
    NSError *error;
    
    if (self.activeController) {
        if (options.completion) {
            options.completion(NO, [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.display" code: 7 userInfo: @{NSLocalizedDescriptionKey: @"Another ad is currently displaying."}]);
        }
        
        return;
    }
    
    if (![[HZDevice currentDevice] HZConnectivityType]) {
        error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.display" code: 1 userInfo: @{NSLocalizedDescriptionKey: @"No internet connection."}];
    } else {
        HZAdModel *ad = [[HZAdLibrary sharedLibrary] popAdForAdUnit:adUnit auctionType:auctionType];
        while (ad != nil && [ad isExpired]) {
            ad = [[HZAdLibrary sharedLibrary] popAdForAdUnit:adUnit auctionType:auctionType];
        }
        
        if (ad != nil) {
            
            // Tags are now set on show. TODO: This may need to find a better home?
            ad.tag = options.tag;
            
            Class controllerClass = [ad controller];
            
            if (controllerClass == [HZAdVideoViewController class]) {
                
                HZAdVideoViewController *controller = [[HZAdVideoViewController alloc] initWithAd: (HZVideoAdModel *) ad];
                if (!controller) {
                    result = NO;
                } else {
                    [controller showWithOptions:options];
                    self.activeController = controller;
                    result = YES;
                }
                
            } else if (controllerClass == [HZAdInterstitialViewController class]) {
                HZAdInterstitialViewController *controller = [[HZAdInterstitialViewController alloc] initWithAd: (HZInterstitialAdModel *) ad];
                if (!controller) {
                    result = NO;
                } else {
                    [controller showWithOptions:options];
                    self.activeController = controller;
                    result = YES;
                }
            }
        }
        
        if (!result) {
            error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.display" code: 6 userInfo: @{NSLocalizedDescriptionKey: @"No ad available"}];
        }
    }
    
    if (!result || error) {
        // Not using the standard method here.
        [[[HZAdsManager sharedManager] delegateForAdUnit: adUnit] didFailToShowAdWithTag:options.tag andError: error];
        [HZAdsManager postNotificationName:kHeyzapDidFailToShowAdNotification adUnit:adUnit auctionType:auctionType];
    }
    
    if (options.completion) {
        options.completion(result, error);
    }
}

- (void) hideActiveAd {
    [self.activeController hide];
}

#pragma mark - Option Enabled?

- (BOOL) isOptionEnabled: (HZAdOptions) adOption {
    return ((int)self.options & adOption);
}

#pragma mark - Models

// Do not run this unless the application is terminating.
- (void) cleanup {
    // Let's cleanup the library
    for (HZAdModel *model in [[HZAdLibrary sharedLibrary] peekAtAllAds]) {
        [model cleanup];
    }
}

#pragma mark - Notifications

- (void) registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationWillTerminate:)
                                                 name: UIApplicationWillTerminateNotification object: nil];
}

- (void) applicationWillTerminate: (id) sender {
    [self cleanup];
}


#pragma mark - Singleton

+ (HZAdsManager *)sharedManager {
    static HZAdsManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedManager) {
            sharedManager = [[HZAdsManager alloc] init];
        }
    });
    return sharedManager;
}

#pragma mark - Delegation

- (void)setInterstitialDelegate:(id<HZAdsDelegate>)delegate
{
    self.interstitialDelegateProxy.forwardingTarget = delegate;
}
- (void)setIncentivizedDelegate:(id<HZAdsDelegate>)delegate
{
    self.incentivizedDelegateProxy.forwardingTarget = delegate;
}
- (void)setVideoDelegate:(id<HZAdsDelegate>)delegate
{
    self.videoDelegateProxy.forwardingTarget = delegate;
}

- (id)delegateForAdUnit:(NSString *)adUnit {
    if ([adUnit isEqualToString:@"incentivized"]) {
        return self.incentivizedDelegateProxy;
    } else if ([adUnit isEqualToString:@"video"]) {
        return self.videoDelegateProxy;
    } else {
        return self.interstitialDelegateProxy;
    }
}

// Send out NSNotifications so mediation can get more info than delegate callbacks provide (e.g. auctionType, easier access to adUnit).
// See HZNotification for details.
+ (void)postNotificationName:(NSString *const)notificationName adUnit:(NSString *)adUnit auctionType:(HZAuctionType)auctionType {
    HZAdInfo *const info = [[HZAdInfo alloc] initWithAdUnit:adUnit auctionType:auctionType];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:info];
}

+ (void)postNotificationName:(NSString *const)notificationName infoProvider:(id<HZAdInfoProvider>)infoProvider {
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:[[HZAdInfo alloc] initWithProvider:infoProvider]];
}

@end
