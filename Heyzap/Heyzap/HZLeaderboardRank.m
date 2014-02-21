//
//  HZLeaderboardRank.m
//  Heyzap
//
//  Created by Daniel Rhodes on 10/11/12.
//
//

#import "HZLeaderboardRank.h"
#import "HZLeaderboardLevel.h"
#import "HeyzapSDKPrivate.h"
#import "HZScore.h"
#import "HZDictionaryUtils.h"
#import "HZAPIClient.h"

#define kBestScoreKey @"bestScore"
#define kCurrentScoreKey @"currentScore"
#define kLevelKey @"level"
#define kUserPictureKey @"userPicture"
#define kPersonalBestKey @"personalBest"
#define kLoggedInKey @"loggedIn"
#define kRanksKey @"ranks"

@interface HZLeaderboardRank()

@property (nonatomic, strong) HZScore *bestScore;
@property (nonatomic, strong) HZScore *currentScore;
@property (nonatomic, strong) HZLeaderboardLevel *level;
@property (nonatomic, strong) NSURL *userPicture;
@property (nonatomic) BOOL currentIsPersonalBest;
@property (nonatomic) BOOL loggedIn;

@end

@implementation HZLeaderboardRank

#pragma mark - Class Methods


- (id) initWithDictionary:(NSDictionary *)dictionary andCurrentScore: (HZScore *) score {
    self = [super init];
    if (self) {
        
        self.currentIsPersonalBest = [[HZDictionaryUtils hzObjectForKey: @"personal_best" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO] withDict: dictionary] boolValue];
        
        if (self.currentIsPersonalBest) {
            self.bestScore = score;
            [self.bestScore setScoreRank: [[HZDictionaryUtils hzObjectForKey: @"rank" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 0] withDict: dictionary] intValue]];
            
        } else {        
            self.bestScore = [[HZScore alloc] init];
            self.bestScore.submittable = NO;
            self.bestScore.relativeScore = [[HZDictionaryUtils hzObjectForKey: @"best_score" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 0] withDict: dictionary] floatValue];
            self.bestScore.displayScore = [HZDictionaryUtils hzObjectForKey: @"best_display_score" ofClass: [NSString class] default: @"" withDict: dictionary];
            [self.bestScore setScoreRank: [[HZDictionaryUtils hzObjectForKey: @"best_rank" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 0] withDict: dictionary] intValue]];
        }
        
        self.level = [[HZLeaderboardLevel alloc] initWithDictionary: [HZDictionaryUtils hzObjectForKey: @"level" ofClass: [NSDictionary class] default: @{} withDict: dictionary]];
        
        self.userPicture = [NSURL URLWithString: [HZDictionaryUtils hzObjectForKey: @"picture" ofClass: [NSString class] default: @"" withDict: dictionary]];
        
        self.loggedIn = [[HZDictionaryUtils hzObjectForKey: @"logged_in" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO] withDict: dictionary] boolValue];
        
        self.ranks = [HZDictionaryUtils hzObjectForKey: @"stream" ofClass: [NSArray class] default: @[] withDict: dictionary];
        
        if (score != nil) {
            [score setScoreRank: [[HZDictionaryUtils hzObjectForKey: @"rank" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 0] withDict: dictionary] intValue]];
            
            self.currentScore = score;
        }
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.bestScore = [aDecoder decodeObjectForKey: kBestScoreKey];
        self.level = [aDecoder decodeObjectForKey: kLevelKey];
        self.currentScore = [aDecoder decodeObjectForKey: kCurrentScoreKey];
        self.userPicture = [aDecoder decodeObjectForKey: kUserPictureKey];
        self.currentIsPersonalBest = [aDecoder decodeBoolForKey: kPersonalBestKey];
        self.loggedIn = [aDecoder decodeBoolForKey: kLoggedInKey];
        self.ranks = [aDecoder decodeObjectForKey: kRanksKey];
    }
    
    return self;
}

- (void) setScoreIfPersonalBest: (HZScore *) score {
    BOOL isPersonalBest = NO;
    self.currentScore = score;
    if (self.bestScore && score && self.level) {
        if (self.level.lowestScoreFirst && score.relativeScore < self.bestScore.relativeScore) {
            isPersonalBest = YES;
        } else if (!self.level.lowestScoreFirst && score.relativeScore > self.bestScore.relativeScore) {
            isPersonalBest = YES;
        } else {
            isPersonalBest = NO;
        }
        
        if (isPersonalBest) {
            self.bestScore = score;
            self.currentIsPersonalBest = YES;
        } else {
            self.currentIsPersonalBest = NO;
        }
    }
}

- (void) clearRanks {
    self.ranks = nil;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject: self.bestScore forKey: kBestScoreKey];
    [aCoder encodeObject: self.level forKey: kLevelKey];
    [aCoder encodeObject: self.currentScore forKey: kCurrentScoreKey];
    [aCoder encodeObject: self.userPicture forKey: kUserPictureKey];
    [aCoder encodeBool: self.currentIsPersonalBest forKey: kPersonalBestKey];
    [aCoder encodeBool: self.loggedIn forKey: kLoggedInKey];
    [aCoder encodeObject: self.ranks forKey: kRanksKey];
}

@end
