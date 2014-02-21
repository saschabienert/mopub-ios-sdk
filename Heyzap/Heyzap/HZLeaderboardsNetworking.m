//
//  HZLeaderboardsNetworking.m
//  Heyzap
//
//  Created by Daniel Rhodes on 3/28/13.
//
//

#import "HZLeaderboardsNetworking.h"
#import "HZAPIClient.h"
#import "HZLeaderboardRank.h"
#import "HZUtils.h"
#import "HZLog.h"
#import "HeyzapSDK.h"
#import "HZUserDefaults.h"
#import "HZAnalytics.h"
#import "HZLeaderboardRank.h"
#import "HeyzapSDKPrivate.h"

#define LEADERBOARD_ENDPOINT @"/in_game_api/leaderboard/everyone"

@implementation HZLeaderboardsNetworking

+ (void)showLeaderboardWithCompletion:(void(^)(HZLeaderboardRank *rank, NSError *error))block {
    
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    [[HZAPIClient sharedClient] get: LEADERBOARD_ENDPOINT
                         withParams:@{@"for_game_store_id" : appID}
                            success:^(id json){
                                HZLeaderboardRank *rank = [[self class] ranksFromJSON:json];
                                
                                block ? block(rank, nil) : nil;
                                
                            } failure:^(NSError *error){
                                block ? block(nil, error) : nil;
                                [HZLog error:[NSString stringWithFormat:@"There was an error getting ranks from Heyzap. The error was: %@",error]];
                            }];
}

+ (void)showLeaderboardLevel: (NSString *) level withCompletion: (void(^)(HZLeaderboardRank *rank, NSError *error))block {
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    [[HZAPIClient sharedClient] get: LEADERBOARD_ENDPOINT
                         withParams:@{@"for_game_store_id" : appID, @"level": level}
                            success:^(id json){
                                HZLeaderboardRank *rank = [[self class] ranksFromJSON:json];
                                block ? block(rank, nil) : nil;
                                
                            }failure:^(NSError *error){
                                block ? block(nil, error) : nil;
                                [HZLog error:[NSString stringWithFormat:@"There was an error getting ranks from Heyzap. The error was: %@",error]];
                            }];
}

+ (HZLeaderboardRank *) ranksFromJSON:(id)json {
    HZLeaderboardRank *rank = [[HZLeaderboardRank alloc] initWithDictionary: json andCurrentScore: nil];
    return rank;
}

+ (void) leaderboardLevelsWithCompletion: (void(^)(NSArray *levels, NSError *error))block {
    
}

+ (void)deleteCurrentUserScoresForLevel:(NSString *)levelID
{
    if (!levelID) return;
    
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    [[HZAPIClient sharedClient] post:@"/in_game_api/leaderboard/delete_scores_for_user_for_level"
                          withParams:
     @{
     @"for_game_store_id" : appID,
     @"level": levelID
     }
                             success:^(id response) {
                                 NSLog(@"Success deleting scores = %@",response);
                             } failure:^(NSError *error) {
                                 NSLog(@"error deleting scores = %@",error);
                             }];
}

@end
