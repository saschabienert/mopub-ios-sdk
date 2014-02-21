//
//  LeaderboardLevelCell.m
//  HeyZap
//
//  Created by Daniel Rhodes on 10/8/12.
//  Copyright (c) 2012 Smart Balloon, Inc. All rights reserved.
//

#import "HZLeaderboardLevelCell.h"
#import "HZLeaderboardLevel.h"
#import <QuartzCore/QuartzCore.h>

#define HZUIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation HZLeaderboardLevelCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.levelNameLabel = [[UILabel alloc] initWithFrame: CGRectMake(10.0, 7.0, 220.0, 15.0)];
        self.levelNameLabel.text = @"Easy Mode Blah Blah Blah";
        self.levelNameLabel.backgroundColor = [UIColor clearColor];
        self.levelNameLabel.font = [UIFont boldSystemFontOfSize: 16.0];
        self.levelNameLabel.textColor = HZUIColorFromRGB(0x4c4c4c);
        [self addSubview: self.levelNameLabel];
        
        self.scoreLabel = [[UILabel alloc] initWithFrame: CGRectMake(10.0, 25.0, 200.0, 15.0)];
        self.scoreLabel.text = @"1939.0";
        self.scoreLabel.font = [UIFont systemFontOfSize: 12.0];
        self.scoreLabel.textColor = HZUIColorFromRGB(0x449905);
        self.scoreLabel.backgroundColor = [UIColor clearColor];
        [self addSubview: self.scoreLabel];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImage *image = [UIImage imageNamed: @"icon_check.png"];
        self.checkmarkIcon = [[UIImageView alloc] initWithImage: image];
        self.checkmarkIcon.frame = CGRectMake(220.0, 15.0, image.size.width, image.size.height);
        [self addSubview: self.checkmarkIcon];
        
        self.bottomBorder = [self cellBorderWithWidth:self.frame.size.width];
        [self.contentView.layer addSublayer:self.bottomBorder];
    }
    
    return self;
}

- (CALayer *)cellBorderWithWidth:(CGFloat)width
{
    CALayer *bottomGrayBorder = [CALayer layer];
    bottomGrayBorder.backgroundColor = [UIColor colorWithRed:216.0f/255.0f
                                                       green:216.0f/255.0f
                                                        blue:216.0f/255.0f
                                                       alpha:1].CGColor;
    
    
    CALayer *bottomWhiteBorder = [CALayer layer];
    bottomWhiteBorder.backgroundColor = [UIColor colorWithRed:255.0f/255.0f
                                                        green:255.0f/255.0f
                                                         blue:255.0f/255.0f
                                                        alpha:1].CGColor;
    
    
    CGFloat grayBorderHeight = 2.0f/[UIScreen mainScreen].scale;
    CGFloat whiteBorderHeight = 1.0f/[UIScreen mainScreen].scale;
    
    bottomGrayBorder.frame = CGRectMake(0.0f, 0, width, grayBorderHeight);
    bottomWhiteBorder.frame = CGRectMake(0.0f, grayBorderHeight, width, whiteBorderHeight);
    
    CALayer *borders = [CALayer layer];
    borders.frame = CGRectMake(0, 0, width, grayBorderHeight+whiteBorderHeight);
    [borders addSublayer:bottomGrayBorder];
    [borders addSublayer:bottomWhiteBorder];
    
    return borders;
}

- (void) setLevel:(HZLeaderboardLevel *)level {
    self.levelNameLabel.text = level.name;    
    self.rankLabel.frame = CGRectMake(self.scoreLabel.frame.origin.x + self.scoreLabel.frame.size.width, 25.0, 150.0, 15.0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setHighlighted: (BOOL)highlighted animated: (BOOL)animated
{
    if (highlighted) {
        [self setBackgroundColor: [UIColor colorWithRed: 216.0/255.0 green: 226.0/255.0 blue: 234.0/255.0 alpha: 1.0]];
    } else {
        [self setBackgroundColor: [UIColor clearColor]];
    }
}

- (void) layoutSubviews {
    self.checkmarkIcon.hidden = !self.selected;
}

@end
