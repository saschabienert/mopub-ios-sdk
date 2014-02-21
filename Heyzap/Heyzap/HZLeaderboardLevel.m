//
//  HZLeaderboardLevel.m
//  Heyzap
//
//  Created by Daniel Rhodes on 10/12/12.
//
//

#import "HZLeaderboardLevel.h"
#import "HeyzapSDKPrivate.h"
#import "HZDictionaryUtils.h"
#import "HZAPIClient.h"

#define kLevelIDKey @"levelID"
#define kNameKey @"name"
#define kDirectionKey @"kDirectionKey"

#define LEVELS_ENDPOINT @"/in_game_api/leaderboard/levels"

@implementation HZLeaderboardLevel

- (id) initWithDictionary: (NSDictionary *) dictionary {
    self = [super init];
    if (self) {
        _levelID = [HZDictionaryUtils hzObjectForKey: @"id" ofClass: [NSString class] default: @"" withDict: dictionary];
        _name = [HZDictionaryUtils hzObjectForKey: @"name" ofClass: [NSString class] default: @"" withDict: dictionary];
        _lowestScoreFirst = [[HZDictionaryUtils hzObjectForKey: @"lowest_score_first" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO] withDict: dictionary] boolValue];
        _everyoneCount = [HZDictionaryUtils hzObjectForKey: @"everyone_count" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 0] withDict: dictionary];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _levelID = [aDecoder decodeObjectForKey: kLevelIDKey];
        _name = [aDecoder decodeObjectForKey: kNameKey];
        _lowestScoreFirst = [aDecoder decodeBoolForKey: kDirectionKey];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject: _levelID forKey: kLevelIDKey];
    [aCoder encodeObject: _name forKey:  kNameKey];
    [aCoder encodeBool: _lowestScoreFirst forKey: kDirectionKey];
}

#pragma mark - Network Methods

+ (void)levelsWithCompletion: (void(^)(NSArray *levels, NSError *error))block {
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    [[HZAPIClient sharedClient] get: LEVELS_ENDPOINT
                         withParams:@{@"for_game_store_id" : appID}
                            success:^(id json){
                                
                                NSArray *rawLevels = [json objectForKey: @"leaderboards"];
                                if (rawLevels) {
                                    NSMutableArray *levels = [[NSMutableArray alloc] initWithCapacity: [rawLevels count]];
                                    if ([rawLevels count] > 0) {
                                        for (NSDictionary *rawLevel in rawLevels) {
                                            HZLeaderboardLevel *level = [[HZLeaderboardLevel alloc] initWithDictionary: rawLevel];
                                            [levels addObject: level];
                                        }
                                    }
                                    
                                    if (block) {
                                        block(levels, nil);
                                    }
                                 } else {
                                     if (block) {
                                         NSError *error = [NSError errorWithDomain: @"com.heyzap.sdk" code: 500 userInfo: json];
                                         block(nil, error);
                                     }
                                 }
                            } failure:^(NSError *error){
                                block ? block(nil, error) : nil;
                            }];
}


@end
