//
//  HeyzapUnitySDK.m
//
//  Copyright 2013 Smart Balloon, Inc. All Rights Reserved
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

#import "HeyzapUnitySDK.h"
#import "HZScore.h"

void UnityPause(bool pause);
extern void UnitySendMessage(const char *, const char *, const char *);

@interface HeyzapSDK ()
+ (BOOL)canOpenHeyzap;
+ (void)setFramework:(NSString *)framework;
+ (void)startHeyzapWithAppId:(NSString *)appId andAppURL:(NSURL *)url andHidePopover:(BOOL)hide;
+ (void)startHeyzapWithAppId:(NSString *)appId andHidePopover:(BOOL)hide;
@end

@implementation HeyzapUnitySDK

- (void) heyzapWillAppear:(BOOL)animated {
    UnityPause(true);
}

- (void) heyzapWillDisappear:(BOOL)animated {
    UnityPause(false);
}

- (void) heyzapDidDisappear:(BOOL)animated {
    UnityPause(false);
}

@end

extern "C" {
    bool is_setup = false;
    
    void hz_start(int appId, char *urlSchema, int flags) {
        if (is_setup == false) {
            
            NSString *ns_appid = [NSString stringWithFormat: @"%i", appId];
            NSString *ns_appurl = [NSString stringWithUTF8String: urlSchema];
            
            [HeyzapUnitySDK setFramework:@"unity3d"];
            [HeyzapUnitySDK setAppName:@""];
            
            if ( [ns_appurl length] == 0) {
                [HeyzapUnitySDK startHeyzapWithAppId:ns_appid
                                          andOptions: flags];
            } else {
                [HeyzapUnitySDK startHeyzapWithAppId:ns_appid
                                           andAppURL:[NSURL URLWithString:ns_appurl]
                                          andOptions: flags];
            }
            
            [[HeyzapUnitySDK sharedSDK] onStartLevel: ^(NSString *levelId) {
                UnitySendMessage("Heyzap", "requestLevel", [levelId UTF8String]);
            }];
            
            is_setup = true;
        }
    }

    void hz_submit_score(const char *realScore, const char *displayScore, const char *levelId) {
        if (is_setup) {
           HZScore *score = [[HZScore alloc] initWithLevelID: [NSString stringWithUTF8String: levelId]];
           score.relativeScore = [[NSString stringWithUTF8String:realScore] floatValue];
           score.displayScore = [NSString stringWithUTF8String: displayScore];
           
           if ([score isValid]) {
               [[HeyzapUnitySDK sharedSDK] submitScore: score withCompletion: nil];
           }
        }
    }

    void hz_show_leaderboard(const char *levelId) {
       if (is_setup) {
           NSString *level = [NSString stringWithUTF8String:levelId];
           if ([level length] == 0) {
               [[HeyzapUnitySDK sharedSDK] openLeaderboard];
           } else {
               [[HeyzapUnitySDK sharedSDK] openLeaderboardLevel:level];
           }
       }
    }

    void hz_show_achievements(void) {
       if (is_setup) {
           [[HeyzapSDK sharedSDK] showAllAchievementsWithCompletion:nil];
       }
    }  

    void hz_unlock_achievements(const char *achievementIDs) {
       if (is_setup) {
           NSArray *achievements = nil;
           if (achievementIDs) {
               NSString *NSAchievementID = [NSString stringWithUTF8String:achievementIDs];
               achievements = [NSAchievementID componentsSeparatedByString:@","];
           }
           
           [[HeyzapUnitySDK sharedSDK] silentlyUnlockAchievements:achievements];
           [[HeyzapUnitySDK sharedSDK] unlockAchievementsWithIDs:achievements completion:nil];
       }
    }

    void hz_checkin(const char *message) {
        if (is_setup) {

        }
    }

    void hz_set_flags(int flags) {
        if (is_setup) {

        }
    }

    bool hz_is_supported() {
        return true;
    }
}