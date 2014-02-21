//
//  HZAchievementsNetworking.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/11/12.
//
//

#import "HZAchievementsNetworking.h"
#import "HZAPIClient.h"
#import "HZAchievement.h"
#import "HZAchievementsTableViewPopup.h"
#import "HZUtils.h"
#import "HZLog.h"
#import "HZArrayUtils.h"
#import "HeyzapSDK.h"
#import "HZUserDefaults.h"
#import "HZAnalytics.h"

@implementation HZAchievementsNetworking

NSString * const kHeyzapAchievementsKey;

+ (void)showAllAchievementsWithCompletion:(void(^)(NSArray *achievements, NSError *error, BOOL *showPopup))block
{
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    [[HZAPIClient sharedClient] get:@"in_game_api/achievements/get_achievements"
                         withParams:@{@"for_game_store_id" : appID}
                            success:^(id json){
                                NSArray *achievements = [[self class] achievementsFromJSON:json];
                                BOOL showPopup = YES;
                                block ? block(achievements, nil, &showPopup) : nil;
                                if (achievements && [achievements count] > 0) {
                                    if (showPopup) {
                                        [HZAnalytics logAnalyticsEvent:@"achievements_dialog_all_shown"];
                                        [[self class] showPopupWithName:@"Achievements"
                                                           achievements:achievements
                                                          configuration:HZTableViewPopupConfigurationTinyFooter];
                                    } else {
                                        [HZLog debug:@"Not showing popup because the BOOL *showPopup was set to NO."];
                                    }
                                
                                } else {
                                    [HZLog info:[NSString stringWithFormat:@"There weren't any achievements to show. The JSON response from Heyzap's server's was %@",json]];
                                }
                                
    }failure:^(NSError *error){
        BOOL showPopup = YES;
        block ? block(nil, error, &showPopup) : nil;
        [HZLog error:[NSString stringWithFormat:@"There was an error getting achievements from Heyzap. The error was: %@",error]];
    }];
}

+ (NSArray *)filterAchievementsToStrings:(NSArray *)achievementIDs {
    return [HZArrayUtils map:^id(id obj) {
        if ([obj conformsToProtocol:@protocol(HeyzapAchievementProtocol)]) {
            return [obj heyzapAchievementIdentifier];
        } else {
            return obj;
        }
    } fromArray: achievementIDs];
}

+ (void)addAchievementsToUnlockQueue:(NSArray *)achievementIDs
{
    if (!achievementIDs || [achievementIDs count] < 1) {
        [HZLog debug:[NSString stringWithFormat:@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__]];
        [HZLog error:[NSString stringWithFormat:@"There weren't any achievement IDs passed to unlock. The array passed was: %@",achievementIDs]];
        return;
    }
    achievementIDs = [[self class] filterAchievementsToStrings:achievementIDs];
    [HZLog debug:[NSString stringWithFormat:@"Storing the achievements to unlock later with IDs: %@",achievementIDs]];
    
    NSArray *previousAchievements =  [[HZUserDefaults sharedDefaults] objectForKey:kHeyzapAchievementsKey];
    
    NSArray *combinedAchievements = [[self class] concatenateAchievements:achievementIDs withAchievements:previousAchievements];
    
    [[HZUserDefaults sharedDefaults] setObject:combinedAchievements forKey:kHeyzapAchievementsKey];
}

+ (NSArray *)concatenateAchievements:(NSArray *)achievements withAchievements:(NSArray *)otherAchievements
{
    if (!achievements || [achievements count] == 0) {
        return otherAchievements;
    } else if (!otherAchievements || [otherAchievements count] == 0) {
        return achievements;
    } else {
        NSMutableSet *combinedAchievements = [NSMutableSet setWithArray:achievements];
        [combinedAchievements unionSet:[NSSet setWithArray:otherAchievements]];
        return [combinedAchievements allObjects];
    }
}

+ (void)unlockAchievementsWithIDs:(NSArray *)achievementIDs completion:(void(^)(NSArray *achievements, NSError *error, BOOL *showPopup))block;
{
    achievementIDs = [[self class] filterAchievementsToStrings:achievementIDs];
    
    NSArray *storedAchievements = [[HZUserDefaults sharedDefaults] objectForKey:kHeyzapAchievementsKey];
    achievementIDs = [[self class] concatenateAchievements:achievementIDs withAchievements:storedAchievements];
    
    
    
    if (!achievementIDs) {
        [HZLog debug:[NSString stringWithFormat:@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__]];
        [HZLog debug:[NSString stringWithFormat:@"There weren't any achievement IDs passed or stored using the `addAchievementsToUnlockQueue` method, so we won't display the popup. The array passed was: %@",achievementIDs]];
        NSError *error = [NSError errorWithDomain:@"HeyzapAchievements" code:0 userInfo:@{NSLocalizedDescriptionKey : @"There weren't any achievement IDs to unlock"}];
        BOOL showPopup = NO;
        block ? block(nil, error, &showPopup) : nil;
        return;
    }
    
    [HZLog debug:[NSString stringWithFormat:@"The achievement IDs we're passing to the heyzap servers to unlock are %@",achievementIDs]];
    
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    NSString *md5 = [HZUtils MD5FromString:[[achievementIDs componentsJoinedByString:@","] stringByAppendingString:appID]];
    [[HZAPIClient sharedClient] get:@"in_game_api/achievements/unlock"
                         withParams:@{
     @"key":md5,
     @"for_game_store_id" : appID,
     @"achievement_ids":[achievementIDs componentsJoinedByString:@","]}
                            success:^(id json){
                                NSArray *achievements = [[self class] achievementsFromJSON:json];
                                BOOL showPopup = YES;
                                block ? block(achievements, nil, &showPopup) : nil;
                                
                                NSString *status = [json objectForKey:@"status"];
                                if (status) {
                                    if ([status intValue] == 200) {
                                        [[HZUserDefaults sharedDefaults] removeObjectForKey:kHeyzapAchievementsKey];
                                    }
                                }
                                if (achievements && [achievements count] > 0) {
                                    if (showPopup) {
                                        [HZAnalytics logAnalyticsEvent:@"achievements_dialog_unlocked_shown"];
                                        [[self class] showPopupWithName:@"New Achievement Unlocked!"
                                                           achievements:achievements
                                                          configuration:HZTableViewPopupConfigurationStandardFooter];
                                    } else {
                                        [HZLog debug:@"Not showing popup because the BOOL *showPopup was NO."];
                                    }
                                } else {
                                    [HZLog info:[NSString stringWithFormat:@"There weren't any achievements to show. The JSON response from Heyzap's server's was %@",json]];
                                }
                            }
                            failure:^(NSError *error){
                                BOOL showPopup = NO;
                                block ? block(nil, error, &showPopup) : nil;
                                [HZLog error:[NSString stringWithFormat:@"There was an error getting achievements from Heyzap. The error was: %@",error]];
                            }];
}

+ (void)deleteAllAchievementsForCurrentUser
{
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    NSString *md5 = [HZUtils MD5FromString:appID];
    [[HZAPIClient sharedClient] post:@"in_game_api/achievements/lock_all"
                          withParams:
     @{
     @"key": md5,
     @"for_game_store_id" : appID,
     }
                             success:^(id response) {
                                 NSLog(@"Success = %@",response);
                             } failure:^(NSError * error) {
                                 NSLog(@"Failure w/ error = %@",error);
                             }];
}

+ (NSArray *)achievementsFromJSON:(id)json
{
    NSArray *achievements = [json objectForKey:@"achievements"];
    NSMutableArray *achievementObjects = [NSMutableArray array];
    
    for (NSDictionary *dictionary in achievements) {
        HZAchievement *achievement = [[HZAchievement alloc] initWithDictionary:dictionary];
        if (achievement) {
            [achievementObjects addObject:achievement];
        }
    }
    return achievementObjects;
}

+ (void)showPopupWithName:(NSString *)name achievements:(NSArray *)achievements configuration:(HZTableViewPopupConfiguration)configuration
{
    
    HZAchievementsTableViewPopup *popup = [[HZAchievementsTableViewPopup alloc] init];
    popup.headerLabel.text = name;
    popup.achievements = achievements;
    popup.configuration = configuration;
    [popup show];
}

@end
