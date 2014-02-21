//
//  HZLeaderboardsNetworking.h
//  Heyzap
//
//  Created by Daniel Rhodes on 3/28/13.
//
//

#import <Foundation/Foundation.h>

@class HZLeaderboardRank;

@interface HZLeaderboardsNetworking : NSObject

+ (void)showLeaderboardWithCompletion:(void(^)(HZLeaderboardRank *rank, NSError *error))block;
+ (void)showLeaderboardLevel: (NSString *) level withCompletion: (void(^)(HZLeaderboardRank *rank, NSError *error))block;

+ (void) leaderboardLevelsWithCompletion: (void(^)(NSArray *levels, NSError *error))block;

+ (void)deleteCurrentUserScoresForLevel:(NSString *)levelID;

@end
