//
//  HeyzapSDK.m
//
//  Copyright 2011 Smart Balloon, Inc. All Rights Reserved
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "HeyzapSDKPrivate.h"
#import "HZCheckinButton.h"
#import "HZPopup.h"
#import "HZSelectorReplacer.h"
#import "HZAnalytics.h"
#import "HZLeaderboardRank.h"
#import "HZScorePopup.h"
#import "HZUserDefaults.h"
#import "HZAFNetworking.h"
#import "HZLog.h"
#import "HZAchievementsNetworking.h"
#import "objc/runtime.h"
#import "HZAPIClient.h"
#import "HZLeaderboardPopup.h"
#import "HZPersonalBestPopup.h"
#import "HZGame.h"
#import "HZUser.h"
#import "HZPlaySharedPopup.h"
#import "HZAvailability.h"
#import "HZLeaderboardsNetworking.h"
#import "HZUtils.h"
#import "HeyzapAds.h"
#import "HZInterstitialAd.h"
#import <StoreKit/StoreKit.h>
#import "HZDictionaryUtils.h"

#define _HZAFNetworking_ALLOW_INVALID_SSL_CERTIFICATES_ @"true"

#define HEYZAP_APP_ID @"435333429"

#define HEYZAP_APP_URL_BASE @"heyzap://checkin?app_store_id=%@&next=%@"
#define HEYZAP_STORE_URL [NSURL URLWithString:@"http://itunes.apple.com/us/app/heyzap/id435333429?mt=8"]

#define POPUP_LAST_SHOWN_KEY @"popup.lastshown"
#define USER_LAST_LEFT_TO_CHECKIN_AT_KEY @"checkin.userleftto"
#define FIRST_APP_OPEN @"first_app_open"
#define LEADERBOARD_KEY @"leaderboard.%@"


@interface HeyzapSDK()<SKStoreProductViewControllerDelegate>

@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, strong) UIViewController *fakeyViewController; //used to get the app store to work
@property (nonatomic, strong) NSTimer *installTimer;
@property (nonatomic, copy) void (^startLevelBlock)(NSString *);

@end


@implementation HeyzapSDK

static HeyzapSDK *heyzap = nil;
static BOOL applicationDidDefineOpenURL;
static BOOL firstStart = YES;
static NSString *currentFramework = @"native";
static NSString *appName = nil;

+ (void) setFramework: (NSString *)framework {
    currentFramework = [NSString stringWithString:framework];
}

+ (void) setAppName: (NSString *)passedAppName {
    appName = [NSString stringWithString:passedAppName];
}

+ (NSString *) appName {
    return appName;
}

#pragma mark - Init

+ (void) startHeyzapWithAppId:(NSString *) _appId andShowPopup:(BOOL)showPopup {
    HZOptions opts = HZOptionsNone;
    if (!showPopup) {
        opts |= HZOptionsHideStartScreen;
    }
    [HeyzapSDK startHeyzapWithAppId: _appId andOptions: opts];
}

+ (void) startHeyzapWithAppId:(NSString *) _appId andAppURL: (NSURL *)url andShowPopup:(BOOL)showPopup {
    HZOptions opts = HZOptionsNone;
    if (!showPopup) {
        opts |= HZOptionsHideStartScreen;
    }
    [HeyzapSDK startHeyzapWithAppId: _appId andAppURL: url andOptions: opts];
}

+ (void) startHeyzapWithAppId:(NSString *)appId andAppURL:(NSURL *)url andOptions:(int)options {
    heyzap = [[[self class] alloc] initWithAppId: appId andAppUrl: url];
    // Log analytics after static instance configured

    [heyzap setOptions: options];
}

+ (void) startHeyzapWithAppId:(NSString *)appId
{
    [self startHeyzapWithAppId:appId andOptions:HZOptionsNone];
}

+ (void) startHeyzapWithAppId:(NSString *)appId andOptions:(int)options {
    heyzap = [[[self class] alloc] initWithAppId: appId];
    // Log analytics after static instance configured
    [heyzap setOptions: options];
}

+ (HZCheckinButton *) getCheckinButtonWithLocation: (CGPoint) location DEPRECATED_ATTRIBUTE {
    HZCheckinButton *button = [HZCheckinButton buttonAtPoint: location];
    return button;
}

+ (HZCheckinButton *) getCheckinButtonWithLocation: (CGPoint) location andMessage: (NSString *) message DEPRECATED_ATTRIBUTE {
    HZCheckinButton *button = [HZCheckinButton buttonAtPoint: location withCheckinMessage: message];
    return button;
}

+ (id) sharedSDK {
    
    if (heyzap == nil) {
        //Throw an exception so the developer knows what went wrong
        @throw [NSException exceptionWithName:@"HeyzapNotLoaded" reason:@"You must ensure that startHeyzapWithAppId: or startHeyzapWithAppId:andAppURL is called first." userInfo:nil];
    }
    
    return heyzap;
}

+ (BOOL) isSupported {
    NSComparisonResult order = [[UIDevice currentDevice].systemVersion compare: @"5.0" options: NSNumericSearch];
    if (order == NSOrderedSame || order == NSOrderedDescending) {
        return YES;
    }
    
    return NO;
}

- (id) initWithAppId: (NSString *)appId {
    if ((self = [super init])) {
        [self setupSDKWithAppID:appId andAppUrl:[[self class] defaultAppURLSchema]];
    }
    
    return self;
}

- (id) initWithAppId:(NSString *) appId andAppUrl:(NSURL *) url {
    if ((self = [super init])) {
        [self setupSDKWithAppID:appId andAppUrl:url];
    }
    
    return self;
}

- (void) setupSDKWithAppID:(NSString *) appId andAppUrl:(NSURL *) url {
    self.appURL = url;
    self.appId = appId;
    
    [HZUtils setAppID: self.appId];
    
    [HZAnalytics sharedInstance];
    
    if (!appName) {
        appName = [HeyzapSDK defaultAppName];
    }
    
    [self registerForNotifications];
    
    applicationDidDefineOpenURL = [HZSelectorReplacer replaceSelector: @selector(application:openURL:sourceApplication:annotation:) onClass: [[UIApplication sharedApplication].delegate class] withSelector: @selector(application:openURL:sourceApplication:annotation:) onClass: [HeyzapSDK class]];
}

- (void) registerAppOpen {
    BOOL first_app_open = [[[HZUserDefaults sharedDefaults] objectForKey:FIRST_APP_OPEN withDefault:(id)kCFBooleanTrue] boolValue];
    if (first_app_open) {
        [[HZAPIClient sharedClient] post:@"in_game_api/v1_mobile/register_new_game_install" withParams:nil success:^(id JSON) {
             [[HZUserDefaults sharedDefaults] setObject:(id)kCFBooleanFalse forKey:FIRST_APP_OPEN];
        } failure:nil];
       
    }
}

#pragma mark - Debug

- (void) logDebugEvent: (NSString *) eventName {
    [HZLog debug: eventName];
}

- (void) setDebugLevel:(HZDebugLevel)debugLevel {
    [HZLog setDebugLevel: debugLevel];
}

#pragma mark - Auth

- (void) login {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Heyzap Login" message: @"" delegate: self cancelButtonTitle: @"Cancel" otherButtonTitles: @"Login", nil];
    [alertView setAlertViewStyle: UIAlertViewStyleLoginAndPasswordInput];
    [alertView setTag: 44];
    [alertView show];
}

- (void) logout {
    [HZUser logout];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 44 && buttonIndex == 1) {
        UITextField *username = [alertView textFieldAtIndex:0];
        UITextField *password = [alertView textFieldAtIndex:1];
        
        [HZUser loginWithUsername: username.text andPassword: password.text withCompletion:^(NSDictionary *data, NSError *error) {
            
        }];
    }
}

#pragma mark - Core

- (IBAction) checkin DEPRECATED_ATTRIBUTE {
    
}

- (IBAction) checkinWithMessage: (NSString *) message DEPRECATED_ATTRIBUTE {

}

- (void) rawCheckin: (NSString *) message {

}

- (void) openLeaderboard {
    [HZAnalytics logAnalyticsEvent: @"score_in_game_overlay_shown_manual"];
    
    if ([HeyzapSDK canOpenHeyzap]) {
        NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"heyzap://leaderboard?app_store_id=%@&next=%@", self.appId, [[[HeyzapSDK sharedSDK] appURL] absoluteString]]];
        [[UIApplication sharedApplication] openURL: url];
    } else {
        HZLeaderboardPopup *popup = [[HZLeaderboardPopup alloc] init];
        popup.headerLabel.text = @"Leaderboard";
        popup.configuration = HZTableViewPopupConfigurationStandardFooterWithClose;
        [popup show];
    }
}

- (void) openLeaderboardLevel:(NSString *)levelId {
    if ([HeyzapSDK canOpenHeyzap]) {
        NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"heyzap://leaderboard/%@?app_store_id=%@&next=%@", levelId, self.appId, [[[HeyzapSDK sharedSDK] appURL] absoluteString]]];
        [[UIApplication sharedApplication] openURL: url];
    } else {
        HZLeaderboardPopup *popup = [[HZLeaderboardPopup alloc] initWithLevelID: levelId];
        popup.headerLabel.text = @"Leaderboard";
        popup.configuration = HZTableViewPopupConfigurationStandardFooterWithClose;
        [popup show];
    }
}

+ (void) openHeyzap {
    [HZUtils openHeyzap];
}

+ (void) redirectToWebWithName: (NSString *)name andParams: (NSDictionary *)params {
    NSString *heyzapInstalled = [HeyzapSDK canOpenHeyzap] ? @"1" : @"0";
    NSMutableDictionary *defaultParams = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                   [HeyzapSDK deviceId], @"device_id",
                                   @"iphone", @"platform",
                                   @"iphone", @"sdk_platform",
                                   @"true", @"from_sdk",
                                   SDK_VERSION, @"sdk_version",
                                   [UIDevice currentDevice].systemVersion, @"ios_version",
                                   [HZAvailability platform], @"device_type",
                                   [[HeyzapSDK sharedSDK] appId], @"app_id",
                                   heyzapInstalled, @"installed",
                                   [[[HeyzapSDK sharedSDK] appURL] absoluteString], @"return_url",
                                   nil];
    
    [defaultParams addEntriesFromDictionary: params];
    
    NSString *urlString = [NSString stringWithFormat: @"https://www.heyzap.com/sdk/redirect/%@?%@", name, [HZDictionaryUtils hzUrlEncodedStringWithDict: defaultParams]];
    
    [HZLog debug: [NSString stringWithFormat: @"Redirecting to: %@", urlString]];
    
    NSURL *url = [NSURL URLWithString: urlString];
    [[UIApplication sharedApplication] openURL: url];
}

// Overloaded
- (void) setOptions:(int)options {
    _options = options;
    
    if (options & HZOptionsShowErrors) {
        [self setDebugLevel: HZDebugLevelError];
    }
}

- (NSURL *) appURL {
    if (_appURL != nil) {
        return _appURL;
    }
    
    return [HeyzapSDK defaultAppURLSchema];
}

#pragma mark - Leaderboards

- (IBAction) submitScore:(HZScore *)score withCompletion: (void(^)(HZLeaderboardRank*, NSError*))completionBlock {
    
    if (score && ![score isValid]) {
        if (completionBlock) {
            NSError *error = [[NSError alloc] initWithDomain: @"com.heyzap.sdk" code: -1 userInfo:@{@"message": @"Score was not valid."}];
            completionBlock(nil, error);
        }
    }
    
    [HZAnalytics logAnalyticsEvent: @"score_received"];
    
    [score attemptToSubmitScoreWithCompletion:^(HZLeaderboardRank *rank, NSError *error) {
        if (rank) {
            if (rank.currentIsPersonalBest) {
                [HZPersonalBestPopup displayPopupWithRank: rank];
            } else {
                [HZScorePopup displayPopupWithRank: rank];
            }
        }
        
        if (error) {
            [HZLog error: [NSString stringWithFormat: @"Score Submission Error: %@", error]];
        }
        
        if (completionBlock) {
            completionBlock(rank, error);
        }
    }];
}

- (void) deleteCurrentUserScoresForLevel:(NSString *)levelID;
{
    [HZLeaderboardsNetworking deleteCurrentUserScoresForLevel:levelID];
}

#pragma mark - Levels

- (void) onStartLevel:(void (^)(NSString *))block {
    if (block) {
        self.startLevelBlock = block;
    }
}

#pragma mark - Utility Methods

+ (NSString *) deviceId {
    return [HZUtils deviceID];
}

+ (NSURL *) defaultAppURLSchema {
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleURLTypes"]) {
        NSArray *urlTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleURLTypes"];
        
        for (NSDictionary *urlType in urlTypes) {
            if ([urlType objectForKey: @"CFBundleURLSchemes"]) {
                NSArray *urls = [urlType objectForKey: @"CFBundleURLSchemes"];
                if ([urls count] > 0) {
                    return [NSURL URLWithString: [NSString stringWithFormat: @"%@://", [urls objectAtIndex: 0]]];
                }
            }
        }
    }
    
    return nil;
}

+ (UIImage *) appImage {
    UIImage *appImage;
    
    NSArray *iconFiles = (NSArray *)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"];
    NSString *iconFile;
    
    if(!iconFiles || (id)iconFiles == [NSNull null]) {
        iconFile = (NSString *) [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleIconFile"];
    } else {
        if ([iconFiles count] > 0) {
            iconFile = [iconFiles objectAtIndex:0];
        } else {
            iconFile = nil;
        }
    }
    
    if (!iconFile || (id)iconFile == [NSNull null]) {
        return nil;
    }
    
    appImage = [UIImage imageNamed:iconFile];
    return  appImage;
}

//Gets the default app name if one hasnt been set. Uses the bundle name.
+ (NSString *) defaultAppName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

//Opens the app store to download Heyzap app
- (void) openAppStore:(NSString *)source {
    
    // Start timer to check for install
    [[HeyzapSDK sharedSDK] startCheckingForInstall:source];
    
    [HZAnalytics logAnalyticsEvent: @"install_button_clicked" andValue:@"true" forKey:@"analytics_directToAppStore"];
    
    if(NSClassFromString(@"SKStoreProductViewController")) { // Checks for iOS 6 feature.
        [HZAnalytics logAnalyticsEvent: @"install_as_popup_shown"];
        
        UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow] ? [[UIApplication sharedApplication] keyWindow] : [[[UIApplication sharedApplication] windows] objectAtIndex: 0];
        
        SKStoreProductViewController *storeController = [[SKStoreProductViewController alloc] init];
        storeController.delegate = self; // productViewControllerDidFinish
        self.fakeyViewController = [[UIViewController alloc] init];
        [self.fakeyViewController.view setBackgroundColor: [UIColor clearColor]];
        
        [mainWindow addSubview: self.fakeyViewController.view];
        
        NSDictionary *productParameters = @{ SKStoreProductParameterITunesItemIdentifier :  HEYZAP_APP_ID};
        
        [storeController loadProductWithParameters: productParameters completionBlock: nil];
        
        [self.fakeyViewController presentViewController:storeController animated:YES completion:nil];
        
    } else {
        [HZAnalytics logAnalyticsEvent: @"install_as_app_shown"];
        
#if !(TARGET_IPHONE_SIMULATOR)
        [[UIApplication sharedApplication] openURL:HEYZAP_STORE_URL];
#else
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"App Store not available!"
                                                        message: @"The App Store is not available on the simulator. On the device this will go to the App Store."
                                                       delegate: nil
                                              cancelButtonTitle: @"OK"
                                              otherButtonTitles: nil, nil];
        [alert show];
#endif
    }
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self.fakeyViewController dismissViewControllerAnimated:YES completion:^{
        [self.fakeyViewController.view removeFromSuperview];
    }];
}

+ (BOOL) canOpenHeyzap {
    return [HZUtils canOpenHeyzap];
}

- (void) openHeyzapWithMessage: (NSString *) message {
    NSString *launchUrl = [NSString stringWithFormat: HEYZAP_APP_URL_BASE, self.appId, [self.appURL absoluteString]];
    if (!message || [message isEqualToString: @""] == NO) {
        launchUrl = [launchUrl stringByAppendingFormat: @"&message=%@", [message stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    }
    NSURL *openUrl = [NSURL URLWithString: launchUrl];
    [[UIApplication sharedApplication] openURL: openUrl];
}

#pragma mark - Application & Notification Callbacks

- (void) registerForNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationBecameActive:)
                                                 name: UIApplicationDidBecomeActiveNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationWillEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification object: nil];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
    if ([[UIApplication sharedApplication]
         respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)])
    {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidEnterBackground:)
                                                     name: UIApplicationDidEnterBackgroundNotification
                                                   object: nil];
    }
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationWillResignActive:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(gameKitPlayerChanged:)
                                                 name: @"GKPlayerDidChangeNotificationName"
                                               object: nil];
}

- (void)gameKitPlayerChanged: (NSNotification *)notification {
    //We are reasonably certain that the game center notification only shows on the first run of the app
    NSComparisonResult order = [[UIDevice currentDevice].systemVersion compare: @"5.0" options: NSNumericSearch];
    if ( firstStart || (order == NSOrderedSame || order == NSOrderedDescending) ) {
        [[HeyzapSDK sharedSDK] logDebugEvent: @"HeyzapSDK: moving popup for game center"];
        [HZPopup moveForGameCenter];
    }
}

- (void)applicationDidEnterBackground: (NSNotification *) notification {
    firstStart = NO;
    
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject: [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: cookiesData forKey: @"com.heyzap.sdk.cookies"];
    [defaults synchronize];
}

- (void)applicationWillEnterForeground: (NSNotification *)notification {
    
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"com.heyzap.sdk.cookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in cookies){
        [cookieStorage setCookie: cookie];
    }
}

- (void)applicationBecameActive: (NSNotification *) notification {
    [[HeyzapSDK sharedSDK] logDebugEvent: @"HeyzapSDK: Resetting timer in became active"];
    self.timer = nil;
    
    // Upload saved scores
    [HZScore uploadSavedScores];
    
    // Do the checkin
    if (self.options & HZOptionsHideStartScreen) {
        return;
    }
    
    [HZGame checkinWithCompletion:^(NSDictionary *data, NSError *error) {
        if (!error && data && ([data objectForKey: @"profile"] != nil)) {
            HZUser *user = [[HZUser alloc] initWithDictionary: [data objectForKey: @"profile"]];
            [HZPlaySharedPopup displayPopupWithUser: user];
        }
    }];
}

- (void) applicationWillResignActive: (NSNotification *) notification {
    [[HeyzapSDK sharedSDK] logDebugEvent: @"HeyzapSDK: Setting timer in resign active"];
    self.timer = [NSDate date];
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        [application endBackgroundTask:backgroundTaskIdentifier];
    }];
    
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if (applicationDidDefineOpenURL) {
        [HZSelectorReplacer replaceSelector:@selector(application:openURL:sourceApplication:annotation:)
                                    onClass:[[UIApplication sharedApplication].delegate class]
                               withSelector:@selector(application:openURL:sourceApplication:annotation:)
                                    onClass:[HeyzapSDK class]];
        
        
        [[[UIApplication sharedApplication] delegate] application: application openURL: url sourceApplication:sourceApplication annotation: annotation];
        
        [HZSelectorReplacer replaceSelector:@selector(application:openURL:sourceApplication:annotation:)
                                    onClass:[[UIApplication sharedApplication].delegate class]
                               withSelector:@selector(application:openURL:sourceApplication:annotation:)
                                    onClass:[HeyzapSDK class]];
    }
    
    if ([HeyzapSDK sharedSDK] && [[HeyzapSDK sharedSDK] startLevelBlock]) {
        if ([HeyzapSDK canParseURL:url]) {
            NSDictionary *components = [HeyzapSDK parseURL:url];
            NSString *requestType = [components objectForKey:kHeyzapRequestTypeKey];
            NSDictionary *requestArguments = [components objectForKey:kHeyzapRequestArgumentsKey];
            if ([requestType isEqualToString:@"level"]) {
                NSString *levelIdentifier = [requestArguments objectForKey:@"level"];
                [[HeyzapSDK sharedSDK] startLevelBlock](levelIdentifier);
            }
            
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)isMultitaskingSupported
{
	BOOL multiTaskingSupported = NO;
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
		multiTaskingSupported = [(id)[UIDevice currentDevice] isMultitaskingSupported];
	}
	return multiTaskingSupported;
}

- (void) dealloc {
    heyzap = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark - Parse URLs from Heyzap

NSString * const kHeyzapRequestTypeKey = @"requestType";
NSString * const kHeyzapRequestArgumentsKey = @"heyzapArguments";

+ (BOOL)canParseURL:(NSURL *)url
{
	if ([[url host] isEqualToString:@"heyzap"]) {
		if ([url pathExtension]) {
			if ([url query]) {
				return YES;
			}
		}
	}
	return NO;
}

+ (NSDictionary *)parseURL:(NSURL *)url;
{
    // Example URL
    // NSURL *url = [NSURL URLWithString:@"hztestapp://heyzap/challenge?level=z&user1=Jenny&user2=Max"];
    
    NSString *host = [url host];
    if ([host isEqualToString:@"heyzap"]) {
        NSString *requestType = [url lastPathComponent];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSArray *pairs = [[url query] componentsSeparatedByString:@"&"];
        for (NSString *pair in pairs) {
            NSArray *elements = [pair componentsSeparatedByString:@"="];
            NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *object = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [dict setObject:object forKey:key];
        }
        
        return @{kHeyzapRequestTypeKey : requestType, kHeyzapRequestArgumentsKey : [dict copy]};
    }
    return nil;
}

NSString * const kHeyzapTimerStartDateKey = @"com.Heyzap.sdkTimerStartDateKey";
NSString * const kHeyzapInstallSourceKey = @"com.Heyzap.sdkInstallSource";

- (void)startCheckingForInstall:(NSString *)source
{
    [self.installTimer invalidate];
    
    self.installTimer = nil;
    if (!source) {
        return;
    }
    if ([HeyzapSDK canOpenHeyzap]) {
        return;
    }
    NSDate *startDate = [NSDate date];
    self.installTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkForInstall:) userInfo:@{kHeyzapTimerStartDateKey : startDate, kHeyzapInstallSourceKey : source} repeats:YES];
}

- (void)checkForInstall:(NSTimer *)timer
{
    NSDictionary *userInfo = timer.userInfo;
    if ([HeyzapSDK canOpenHeyzap]) {
        NSString *source = [userInfo objectForKey:kHeyzapInstallSourceKey];
        if (source) {
            [timer invalidate];
            [HZAnalytics logAnalyticsEvent:source];
        }
    }
    
    NSDate *startDate = [userInfo objectForKey:kHeyzapTimerStartDateKey];
    
    if ([startDate timeIntervalSinceNow] < -600) {
        [timer invalidate];
    }
}


#pragma mark - Achievements

- (void)unlockAchievementsWithIDs:(NSArray *)achievementIDs completion:(void(^)(NSArray *achievements, NSError *error, BOOL *showPopup))block
{
    [HZAchievementsNetworking unlockAchievementsWithIDs:achievementIDs completion:block];
}

- (void)silentlyUnlockAchievements:(NSArray *)achievementIDs
{
    [HZAchievementsNetworking addAchievementsToUnlockQueue:achievementIDs];
}

- (void)showAllAchievementsWithCompletion:(void(^)(NSArray *achievements, NSError *error, BOOL *showPopup))block
{
    [HZAchievementsNetworking showAllAchievementsWithCompletion:block];
}

- (void)deleteAllAchievementsForCurrentUser
{
    [HZAchievementsNetworking deleteAllAchievementsForCurrentUser];
}

@end
