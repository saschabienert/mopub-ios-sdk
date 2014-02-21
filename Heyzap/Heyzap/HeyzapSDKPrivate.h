//
//  HeyzapSDK.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HeyzapSDK.h"
#import "HZCheckinButton.h"
#import "HZScore.h"
#import "HZLeaderboardRank.h"
#import "HZLeaderboardLevel.h"

#define SDK_VERSION @"6.4.0"

typedef void (^HZOuterScoreBlock)(HZLeaderboardRank *, NSError *);
typedef id (^HZInnerScoreBlock)(HZLeaderboardRank *, NSError *, HZOuterScoreBlock);

@interface HeyzapSDK () <UIAlertViewDelegate>

@property (nonatomic, assign) BOOL hidePopover;
@property (nonatomic, strong) NSDate *timer;
@property (nonatomic, assign) HZOptions options;


+ (void) setFramework: (NSString *)framework;

- (id) initWithAppId: (NSString *) appId;
- (id) initWithAppId: (NSString *) appId andAppUrl: (NSURL *) url;

+ (NSString *) deviceId;
+ (NSURL *) defaultAppURLSchema;
+ (NSString *) defaultAppName;
+ (NSString *) appName;
+ (BOOL) canOpenHeyzap;
+ (void) openHeyzap;
+ (void) openAppStore:(NSString *)source;
+ (BOOL) isMultitaskingSupported;
+ (UIImage *) appImage;
+ (void) redirectToWebWithName: (NSString *)name andParams: (NSDictionary *)params;

- (BOOL) canOpenHeyzap;
- (void) openHeyzapWithMessage: (NSString *) message;
- (void) applicationDidEnterBackground: (NSNotification *) notification;
- (void) applicationWillEnterForeground: (NSNotification *)notification;
- (void) applicationWillResignActive: (NSNotification *) notification;

- (BOOL) application: (UIApplication *) application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url;

- (void) registerForNotifications;
- (void) rawCheckin: (NSString *) message;
- (void) logDebugEvent: (NSString *) eventName;


- (void)startCheckingForInstall:(NSString *)source;

- (void) login;
- (void) logout;

- (void) showAdForCreative: (NSString *) creativeID	;

@end

@interface HZCheckinButton ()

@property (nonatomic, strong) UIButton* theButton;

@end

@interface HZScore()
@property (nonatomic, strong) NSDate *dateAdded;
@property (nonatomic) BOOL submittable;

+ (void) uploadSavedScores;
- (void) attemptToSubmitScoreWithCompletion: (void(^)(HZLeaderboardRank*, NSError*))completionBlock;
- (NSDictionary *) params;
- (void) setScoreRank: (int) rank;
@end

@interface HZLeaderboardRank()

@property (nonatomic, strong) NSArray *ranks;

- (id) initWithDictionary: (NSDictionary *) dictionary andCurrentScore: (HZScore *) score;
- (void) clearRanks;
- (void) setScoreIfPersonalBest: (HZScore *) score;

@end

@interface HZLeaderboardLevel()

@property (nonatomic, strong) NSNumber *everyoneCount;

- (id) initWithDictionary: (NSDictionary *) dictionary;
+ (void) levelsWithCompletion: (void(^)(NSArray *levels, NSError *error))block;
@end
