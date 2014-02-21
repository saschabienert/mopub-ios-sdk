//
//  LeaderboardCell.h
//  HeyZap
//
//  Created by Daniel Rhodes on 10/3/12.
//  Copyright (c) 2012 Smart Balloon, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZImageView.h"

typedef enum {
    GLOW_TOP = 0,
    GLOW_BOTTOM = 1
} HZGlowPosition;

@interface HZLeaderboardCell : UITableViewCell

@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) HZImageView *userImageView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UIButton *actionButton;

@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, strong) UIView *bottomAccentLine;
@property (nonatomic, strong) UIView *glowLine;

@property (nonatomic, strong) UIColor *actualBackgroundColor;

@property (nonatomic) BOOL showAccentLines;
@property (nonatomic) HZGlowPosition glowPosition;
@property (nonatomic) BOOL showGlow;

@end
