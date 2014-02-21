//
//  HZScore.m
//  Heyzap
//
//  Created by Daniel Rhodes on 10/11/12.
//
//

#import "HZScore.h"
#import "HZAPIClient.h"
#import "HeyzapSDKPrivate.h"
#import "HZUtils.h"
#import "HeyzapSDK.h"
#import <CommonCrypto/CommonDigest.h>
#import "HZUserDefaults.h"
#import "HZAnalytics.h"
#import "HZDictionaryUtils.h"

@interface HZScore()

- (void) saveToBeUploadedLater;

@end

@implementation HZScore

#pragma mark - Init

- (id) init {
    self = [super init];
    if (self) {
        // Set defaults
        self.submittable = YES;
    }
    
    return self;
}

- (id) initWithLevelID: (NSString *) levelID {
    self = [super init];
    if (self) {
        self.submittable = YES;
        self.levelID = levelID;
    }
    
    return self;
}



- (BOOL) isValid {
    if (!self.displayScore || (self.displayScore && [self.displayScore isEqualToString: @""])) {
        return NO;
    }
    
    if (!self.levelID || (self.levelID && [self.levelID isEqualToString: @""])) {
        return NO;
    }
    
    if (self.username && [self.username isEqualToString: @""]) {
        return NO;
    }
    
    return YES;
}

NSString * const kHeyzapLeaderboardFormatKey = @"leaderboard.%@";

#pragma mark - Private Methods

- (void) attemptToSubmitScoreWithCompletion: (void(^)(HZLeaderboardRank* rank, NSError* error))completionBlock {
    __block NSString *leaderboardKey = [NSString stringWithFormat: kHeyzapLeaderboardFormatKey, [self levelID]];
    __block HZLeaderboardRank *rank = [[HZUserDefaults sharedDefaults] objectForKey: leaderboardKey];
    if ([HeyzapSDK canOpenHeyzap] && rank.loggedIn) {
        rank = nil;
    }
    
    if (self.submittable) {
        [HZAnalytics logAnalyticsEvent: @"score_post_started"];
        
        [[HZAPIClient sharedClient] post: @"in_game_api/leaderboard/new_score" withParams: [self params] success:^(id JSON) {
            NSError *error = nil;
            
            if (JSON && [JSON objectForKey: @"status"]) {
                int statusCode = [[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 0] withDict: JSON] intValue];
                if (statusCode == 200) {
                    [HZAnalytics logAnalyticsEvent: @"score_post_success"];
                    
                    rank = [[HZLeaderboardRank alloc] initWithDictionary: JSON andCurrentScore: self];
                } else {
                    [HZAnalytics logAnalyticsEvent: @"score_post_failure"];
                    
                    // Save the score
                    [self saveToBeUploadedLater];
                    
                    // Set the rank to personal best (doing this here because it's done automatically from server response)
                    if (rank) {
                        [rank setScoreIfPersonalBest: self];
                    }
                    
                    switch(statusCode) {
                        case 512: {
                            error = [[NSError alloc] initWithDomain: @"com.heyzap.sdk" code: 512 userInfo: @{@"message": @"Level identifier not found. Go to the Developer dashboard to resolve this issue."}];
                            break;
                        }
                        default: {
                            // define an error thing here.
                            error = [[NSError alloc] initWithDomain: @"com.heyzap.sdk" code: 1 userInfo: @{@"message": @"Improper response from the server."}];
                            break;
                        }
                    }
                }
            }
            
            // Save the rank
            if (rank) {
                if (error) {
                   [rank clearRanks]; // these ranks are no longer relevant 
                }
                
                [[HZUserDefaults sharedDefaults] setObject: rank forKey: leaderboardKey];
            }
            
            // Return rank and/or appropriate error
            if (completionBlock) {
                completionBlock(rank, error);
            }
            
        } failure: ^(NSError *error) {
            [HZAnalytics logAnalyticsEvent: @"score_post_failure"];
            
            // Save the score
            [self saveToBeUploadedLater];
            
            // Update rank, if it exists and save it.
            if (rank) {
                [rank setScoreIfPersonalBest: self];
                [rank clearRanks]; //these ranks are no longer relevant
                [[HZUserDefaults sharedDefaults] setObject: rank forKey: leaderboardKey];
            }
            
            // Return rank and/or appropriate error
            NSError *completionError = [[NSError alloc] initWithDomain: @"com.heyzap.sdk" code: 0 userInfo: @{NSUnderlyingErrorKey : error}];
            if (completionBlock) {                
                completionBlock(rank, completionError);
            }
        }];
    } else {
        if (completionBlock) {
            NSError *error = [[NSError alloc] initWithDomain: @"com.heyzap.sdk" code: 0 userInfo: @{@"message": @"Score is not submittable"}];
            completionBlock(nil, error);
        }
    }
}

- (NSMutableDictionary *) params {
    
    NSString *scoreString = [NSString stringWithFormat: @"%f", self.relativeScore];
    NSString *keyValue = [NSString stringWithFormat: @"%@%@%@", scoreString, self.displayScore, self.levelID];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        [HZUtils MD5FromString: keyValue], @"key",
                                        self.displayScore, @"display_score",
                                        scoreString, @"score",
                                        self.levelID, @"level", nil];
    if (self.username) {
        [dictionary setObject: self.username forKey: @"game_username"];
    }
    
    if ([HeyzapSDK canOpenHeyzap]) {
        [dictionary setObject: @"true" forKey: @"installed"];
    }
    
    return dictionary;
}

- (void) setScoreRank: (int) rank {
    _rank = rank;
}

#pragma mark - Score Saving

NSString * const kHeyzapSavedScoresArrayKey = @"saved.scores";

- (void) saveToBeUploadedLater {
    // If Heyzap is not installed, let's not save scores and purge any that have been saved.
    if (![HeyzapSDK canOpenHeyzap]) {
        [[HZUserDefaults sharedDefaults] removeObjectForKey:kHeyzapSavedScoresArrayKey];
        return;
    }
    
    NSArray *toBeUploaded = [[HZUserDefaults sharedDefaults] objectForKey: kHeyzapSavedScoresArrayKey];
    if (!toBeUploaded) {
        toBeUploaded = @[];
    }

    NSMutableArray *mutableUploads = [toBeUploaded mutableCopy];
    [mutableUploads addObject: self];
    [[HZUserDefaults sharedDefaults] setObject: [mutableUploads copy] forKey: kHeyzapSavedScoresArrayKey];
}

+ (void) uploadSavedScores {
    // If Heyzap is not installed, let's throw away all saved scores as they might not belong to current user.
    if (![HeyzapSDK canOpenHeyzap]) {
        [[HZUserDefaults sharedDefaults] removeObjectForKey: kHeyzapSavedScoresArrayKey];
        return;
    }
    
    // Get the scores
    NSArray *scores = [[HZUserDefaults sharedDefaults] objectForKey: kHeyzapSavedScoresArrayKey withDefault: @[]];
    
    // Immediately delete old scores. If it fails, it will be added back into array on failure.
    [[HZUserDefaults sharedDefaults] removeObjectForKey: kHeyzapSavedScoresArrayKey];
    
    // Loop through scores and send. Ignore errors.
    if (scores && [scores count] > 0) {
        for(HZScore *score in scores) {
            [score attemptToSubmitScoreWithCompletion: nil];
        }
    }
}

#pragma mark - NSCoding Protocol

NSString * const kHeyzapDisplayScoreKey = @"HeyzapSDKDisplayScoreKey";
NSString * const kHeyzapRelativeScoreKey = @"HeyzapSDKRelativeScoreKey";
NSString * const kHeyzapLevelIDKey = @"HeyzapSDKLevelIDKey";
NSString * const kHeyzapUsernameKey = @"HeyzapSDKUsernameKey";
NSString * const kHeyzapRankKey = @"HeyzapSDKRankKey";
NSString * const kHeyzapDateAddedKey = @"HeyzapSDKDateAddedKey";
NSString * const kHeyzapSubmittableKey = @"HeyzapSDKSubmittableKey";

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.displayScore = [aDecoder decodeObjectForKey:kHeyzapDisplayScoreKey];
        self.relativeScore = [aDecoder decodeFloatForKey:kHeyzapRelativeScoreKey];
        self.levelID = [aDecoder decodeObjectForKey:kHeyzapLevelIDKey];
        self.username = [aDecoder decodeObjectForKey:kHeyzapUsernameKey];
        _rank = [aDecoder decodeIntForKey:kHeyzapRankKey];
        self.dateAdded = [aDecoder decodeObjectForKey:kHeyzapDateAddedKey];
        self.submittable = [aDecoder decodeBoolForKey:kHeyzapSubmittableKey];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.displayScore forKey:kHeyzapDisplayScoreKey];
    [aCoder encodeFloat:self.relativeScore forKey:kHeyzapRelativeScoreKey];
    [aCoder encodeObject:self.levelID forKey:kHeyzapLevelIDKey];
    if (self.dateAdded) {
        [aCoder encodeObject:self.dateAdded forKey:kHeyzapDateAddedKey];
    }
    if (self.submittable) {
        [aCoder encodeBool:self.submittable forKey:kHeyzapSubmittableKey];
    }
    
    if (self.username) {
        [aCoder encodeObject:self.username forKey:kHeyzapUsernameKey];
    }
    if (self.rank) {
        [aCoder encodeInt:self.rank forKey:kHeyzapRankKey];
    }
    
}

@end
