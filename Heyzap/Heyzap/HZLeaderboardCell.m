//
//  LeaderboardCell.m
//  HeyZap
//
//  Created by Daniel Rhodes on 10/3/12.
//  Copyright (c) 2012 Smart Balloon, Inc. All rights reserved.
//

#import "HZLeaderboardCell.h"
#import "HZImageView.h"

@implementation HZLeaderboardCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        // Rank
        self.rankLabel = [[UILabel alloc] initWithFrame: CGRectMake(0.0, 0.0, 44.0, 44.0)];
        self.rankLabel.backgroundColor = [UIColor clearColor];
        self.rankLabel.textAlignment = UITextAlignmentCenter;
        self.rankLabel.font = [UIFont boldSystemFontOfSize: 24.0];
        self.rankLabel.textColor = [UIColor colorWithRed: 76.0/255.0 green:76.0/255.0 blue:76.0/255.0 alpha: 1.0];
        self.rankLabel.shadowColor = [UIColor whiteColor];
        self.rankLabel.adjustsFontSizeToFitWidth = YES;
        self.rankLabel.minimumFontSize = 15.0;
        self.rankLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        [self.contentView addSubview: self.rankLabel];
        
        // Image View
        self.userImageView = [[HZImageView alloc] initWithFrame:CGRectMake(44.0, 0.5, 43.0, 43.0)];
        [self.contentView addSubview: self.userImageView];
        
        // Display Name
        self.displayNameLabel = [[UILabel alloc] initWithFrame: CGRectMake(98.0, 2.0, 150.0, 22.0)];
        self.displayNameLabel.textColor = [UIColor colorWithRed: 76.0/255.0 green: 76.0/255.0 blue: 76.0/255.0 alpha: 1.0];
        self.displayNameLabel.backgroundColor = [UIColor clearColor]; //
        self.displayNameLabel.font = [UIFont boldSystemFontOfSize: 16.0];
        self.displayNameLabel.shadowColor = [UIColor whiteColor];
        self.displayNameLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        [self.contentView addSubview: self.displayNameLabel];

        // Score
        self.scoreLabel = [[UILabel alloc] initWithFrame: CGRectMake(98.0, 18.0, 150.0, 22.0)];
        self.scoreLabel.backgroundColor = [UIColor clearColor];
        self.scoreLabel.textColor = [UIColor colorWithRed: 85.0/255.0 green: 164.0/255.0 blue: 0.0/255.0 alpha: 1.0];
        self.scoreLabel.font = [UIFont systemFontOfSize: 12.0];
        self.scoreLabel.shadowColor = [UIColor whiteColor];
        self.scoreLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        [self.contentView addSubview: self.scoreLabel];
        
        //Action Button
        self.actionButton = [[UIButton alloc] initWithFrame: CGRectMake(203.0, 2.5, 80.0, 40.0)];
        [self.actionButton setBackgroundImage: [UIImage imageNamed: @"Heyzap.bundle/btn-green.png"] forState: UIControlStateNormal];
        [self.actionButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        self.actionButton.titleLabel.font = [UIFont boldSystemFontOfSize: 16.0];
        self.actionButton.titleLabel.shadowColor = [UIColor colorWithWhite: 0.0 alpha: 0.5];
        self.actionButton.titleLabel.shadowOffset = CGSizeMake(0.0, -0.5);
        [self.contentView addSubview: self.actionButton];
        
        // Accent Line
        self.showAccentLines = YES;
        
        self.bottomLine = [[UIView alloc] initWithFrame: CGRectMake(0.0, 0.0, 320.0, 1.0)]; //42.5
        [self.bottomLine setBackgroundColor: [UIColor colorWithRed: 207.0/255.0 green: 207.0/255.0 blue: 207.0/255.0 alpha: 1.0]];
        [self.contentView addSubview: self.bottomLine];
        
        self.bottomAccentLine = [[UIView alloc] initWithFrame: CGRectMake(0.0, 1.0, 320.0, 0.5)]; //43.5
        [self.bottomAccentLine setBackgroundColor: [UIColor whiteColor]];
        [self.contentView addSubview: self.bottomAccentLine];
        
        self.showGlow = NO;
        self.glowPosition = GLOW_TOP;
        
        
        self.glowLine = [[UIView alloc] initWithFrame: CGRectZero];
        if ( 5 <= [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] ) { /// iOS5 is installed
            self.glowLine.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"Heyzap.bundle/leaderboard_glow.png"]];
        }
        [self.contentView addSubview: self.glowLine];
    }
    
    return self;
}

- (void) layoutSubviews {
    self.backgroundColor = self.actualBackgroundColor;
    self.bottomLine.hidden = !self.showAccentLines;
    self.bottomAccentLine.hidden = !self.showAccentLines;
    self.glowLine.hidden = !self.showGlow;
    
    if (self.showGlow) {
        if (self.glowPosition == GLOW_TOP) {
            self.bottomAccentLine.hidden = YES;
            self.bottomLine.hidden = YES;
            self.glowLine.frame = CGRectMake(0.0, -1.0, 320.0, 9.0);
            self.glowLine.transform = CGAffineTransformMakeRotation(M_PI);
        } else {
            self.glowLine.frame = CGRectMake(0.0, self.frame.size.height - 8.0, 320.0, 9.0);
            self.glowLine.transform = CGAffineTransformIdentity;
        }
    }
}

- (void)setHighlighted: (BOOL)highlighted animated: (BOOL)animated
{
    [super setHighlighted: highlighted animated: animated];
}

@end
