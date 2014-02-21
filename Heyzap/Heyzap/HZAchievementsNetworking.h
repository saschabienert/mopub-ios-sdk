//
//  HZAchievementsNetworking.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/11/12.
//
//

#import <Foundation/Foundation.h>

@interface HZAchievementsNetworking : NSObject

+ (void)showAllAchievementsWithCompletion:(void(^)(NSArray *achievements, NSError *error, BOOL *showPopup))block;
+ (void)unlockAchievementsWithIDs:(NSArray *)achievementIDs completion:(void(^)(NSArray *achievements, NSError *error, BOOL *showPopup))block;
+ (void)addAchievementsToUnlockQueue:(NSArray *)achievementIDs;

+ (void)deleteAllAchievementsForCurrentUser;

@end
