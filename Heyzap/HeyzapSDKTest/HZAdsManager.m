//
//  HZAdsManager.m
//  Heyzap
//
//  Created by Daniel Rhodes on 8/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdsManager.h"
#import "HZJAProcessInfo.h"
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

#define HAS_REPORTED_INSTALL_KEY @"hz_install_reported"
#define DEFAULT_RETRIES 3

@implementation HZAdsManager

- (id) init {
    self = [super init];
    if (self) {
        _isEnabled = YES;

        // Does this actually do anything?
//        NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity: 20 * 1024 * 1024
//                                                             diskCapacity:20 * 1024 * 1024
//                                                                 diskPath: [HZUtils cacheDirectoryPath]];
//        [NSURLCache setSharedURLCache:URLCache];
        

        [[self class] runInitialTasks];
    }
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Run Initial Tasks

- (void) onStart {
    if (![self isOptionEnabled: HZAdOptionsInstallTrackingOnly] && ![self isOptionEnabled: HZAdOptionsDisableAutoPrefetching]) {
        [HZInterstitialAd fetch];
    }
}

+ (void) runInitialTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupCachingDirectory];
        
        [self doProcessScan];
        
        //register this game as installed, if we haven't done so already
        if ([[HZUserDefaults sharedDefaults] objectForKey:HAS_REPORTED_INSTALL_KEY withDefault:(id)kCFBooleanFalse]) {
            
            [[HZAdsAPIClient sharedClient] post:@"register_new_game_install" withParams:@{} success:^(id JSON) {
                [[HZUserDefaults sharedDefaults] setObject:(id)kCFBooleanTrue forKey:HAS_REPORTED_INSTALL_KEY];
            } failure:nil];
        }
    });
    
    [self reportInstalledGames];
}

+ (void) setupCachingDirectory {
    [HZUtils createCacheDirectory];
    
    // Delete extraneous data
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath: [HZUtils cacheDirectoryPath] error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'imp'"];
    NSArray *onlyImpressionFiles = [dirContents filteredArrayUsingPredicate:fltr];
    
    for (NSString *filePath in onlyImpressionFiles) {
        [[NSFileManager defaultManager] removeItemAtPath: [HZUtils cacheDirectoryWithFilename: filePath] error: nil];
    }
}

+ (void)reportInstalledGames
{
    // There are some frightening reports of the `canOpenURL:` method being really slow on iOS 7 devices with a SIM card. I wasn't able to replicate this on my 5S running 7.0.3, and even based on the person reporting 1700 URLs taking 22 seconds to check, we should take < 1 second, so I'm figuring we'll be ok.
    // http://vntin.com/openradar.appspot.com/15020847 https://github.com/danielamitay/iHasApp/issues/16 https://twitter.com/agiletortoise/status/371650061416931329
    
    NSString * const dateOfCheckKey = @"dateOfCheckingInstalledGames";
    NSDate *date = [[HZUserDefaults sharedDefaults] objectForKey:dateOfCheckKey];
    const NSTimeInterval oneWeek = 604800;
    if (date && [[NSDate date] timeIntervalSinceDate:date] < oneWeek) {
        return;
    }
    
    [[HZAdsAPIClient sharedClient] get:@"games_to_check.json" withParams:nil success:^(NSArray *response) {
        NSMutableArray *installedGames = [@[] mutableCopy];
        for (NSDictionary *game in response) {
            NSNumber *const gameID = [HZDictionaryUtils hzObjectForKey:@"game_id" ofClass:[NSNumber class] withDict: game];
            
            NSURL *const launchURL = ({
                NSString *launchString = [HZDictionaryUtils hzObjectForKey:@"launch_uri" ofClass:[NSString class] withDict: game];
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
        
        
        [[HZAdsAPIClient sharedClient] post:@"add_initial_packages" withParams:@{@"installed_game_ids": installedGames} success:^(NSDictionary *response) {
            [[HZUserDefaults sharedDefaults] setObject:[NSDate date] forKey:dateOfCheckKey];
        } failure:nil];
        
    } failure:nil];
}

#pragma mark - Enabled

+ (BOOL) isEnabled {
    return NO;
}

#pragma mark - Show

- (void) showForAdUnit: (NSString *) adUnit andTag: (NSString *) tag withCompletion: (void (^)(BOOL result, NSError *error))completion  {
    BOOL result = NO;
    NSError *error;
    
    if (tag == nil) {
        tag = [HeyzapAds defaultTagName];
    }
    
    if ([self activeController] != nil) {
        if (completion) {
            completion(NO, [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.display" code: 7 userInfo: @{NSLocalizedDescriptionKey: @"Another ad is currently displaying."}]);
        }
        
        return;
    }
    
    if (![[HZDevice currentDevice] HZConnectivityType]) {
        error = [NSError errorWithDomain: @"com.heyzap.sdk.ads.error.display" code: 1 userInfo: @{NSLocalizedDescriptionKey: @"No internet connection."}];
    } else {
        if (!tag) {
            tag = [HeyzapAds defaultTagName];
        }
        
        HZAdModel *ad = [[HZAdLibrary sharedLibrary] popAdForAdUnit: adUnit andTag: tag];
        while (ad != nil && [ad isExpired]) {
            ad = [[HZAdLibrary sharedLibrary] popAdForAdUnit: adUnit andTag: tag];
        }
        
        if (ad != nil) {
            Class controllerClass = [ad controller];
            
            if (controllerClass == [HZAdVideoViewController class]) {
                
                HZAdVideoViewController *controller = [[HZAdVideoViewController alloc] initWithAd: (HZVideoAdModel *) ad];
                if (!controller) {
                    result = NO;
                } else {
                    [controller show];
                    self.activeController = controller;
                    result = YES;
                }
                
            } else if (controllerClass == [HZAdInterstitialViewController class]) {
                HZAdInterstitialViewController *controller = [[HZAdInterstitialViewController alloc] initWithAd: (HZInterstitialAdModel *) ad];
                if (!controller) {
                    result = NO;
                } else {
                    [controller show];
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
        if (self.statusDelegate != nil
            && [self.statusDelegate respondsToSelector: @selector(didFailToShowAdWithTag:andError:)]) {
            [self.statusDelegate performSelector: @selector(didFailToShowAdWithTag:andError:) withObject: tag withObject: error];
        }
    }
    
    if (completion) {
        completion(result, error);
    }
}

- (void) hideActiveAd {
    if ([self activeController] != nil) {
        [[self activeController] hide];
    }
}

#pragma mark - Option Enabled?

- (BOOL) isOptionEnabled: (HZAdOptions) adOption {
    return ((int)self.options & adOption);
}

#pragma mark - Process Scanning

+ (void) doProcessScan {
    HZJAProcessInfo *procInfo = [[HZJAProcessInfo alloc] init];
    [procInfo obtainFreshProcessList];
    
    if (procInfo.processList) {
        [[HZAdsAPIClient sharedClient] post:@"add_initial_packages"
                                 withParams:@{@"process_list": procInfo.processList}
                                    success:nil
                                    failure:nil];
    }
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

@end
