//
//  LeaderboardLevelCell.h
//  HeyZap
//
//  Created by Daniel Rhodes on 10/8/12.
//  Copyright (c) 2012 Smart Balloon, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HZLeaderboardLevel;

@interface HZLeaderboardLevelCell : UITableViewCell

@property (nonatomic, strong) HZLeaderboardLevel *level;

@property (nonatomic, strong) UILabel *levelNameLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, strong) UIView *bottomAccentLine;
@property (nonatomic, strong) UIImageView *checkmarkIcon;

@property (nonatomic, strong) CALayer *bottomBorder;

@end
