//
//  HZAchievementTableViewCell.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZAchievementTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "HZAvailability.h"
#import "HZUtils.h"

@interface HZAchievementTableViewCell()

@end

@implementation HZAchievementTableViewCell


// Setting the background colors of the labels as the tableview background color improves performance. Profile using the Core Animation tool and check for 'Color blended layers'
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.nameLabel = [[UILabel alloc] init];
        
        self.nameLabel.textColor = [UIColor colorWithRed:57/255.0f green:57/255.0f blue:57/255.0f alpha:1];
        self.nameLabel.font = [UIFont systemFontOfSize:15];
        self.nameLabel.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:239/255.0f alpha:1];
        
        if (!iPhone4Minus()) {
            self.nameLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
            self.nameLabel.layer.shadowOpacity = 0.75f;
            self.nameLabel.layer.shadowRadius = isRetina() ? 1 : 0.5f;
            self.nameLabel.layer.shadowOffset = CGSizeMake(0, 1);
            self.nameLabel.layer.masksToBounds = NO;
        }
        
        self.nameLabel.frame = CGRectMake(64, 12, 216, 0);
        [self.contentView addSubview:self.nameLabel];
        
        self.subtitleLabel = [[UILabel alloc] init];
        
        self.subtitleLabel.textColor = [UIColor colorWithRed:137/255.0f green:137/255.0f blue:137/255.0f alpha:1];
        self.subtitleLabel.font = [UIFont systemFontOfSize:12];
        self.subtitleLabel.backgroundColor = self.nameLabel.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:239/255.0f alpha:1];
        
        if (!iPhone4Minus()) {
            self.subtitleLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
            self.subtitleLabel.layer.shadowOpacity = 0.75f;
            self.subtitleLabel.layer.shadowRadius = isRetina() ? 1 : 0.5f;
            self.subtitleLabel.layer.shadowOffset = CGSizeMake(0, 1);
            self.subtitleLabel.layer.masksToBounds = NO;
        }
        
        self.subtitleLabel.frame = CGRectMake(64, 34, 216, 0);
        self.subtitleLabel.numberOfLines = 8;
        [self.contentView addSubview:self.subtitleLabel];
        // Set the badge image to half of the version from the server -- means we don't have to stretch it. See core animation profiler: 
        self.badgeImage = [[HZImageView alloc] initWithFrame:CGRectMake(7, 13, 50, 50)];
        
        
        // Default UIImageView contentmode is scale to fill
        [self.contentView addSubview:self.badgeImage];
        
        self.redButton = [[UIImageView alloc] initWithImage:[HZUtils heyzapBundleImageNamed:@"badge_new.png"]];
        self.redButton.frame = CGRectMake(CGRectGetMinX(self.badgeImage.frame)-7, CGRectGetMinY(self.badgeImage.frame)-4, 36, 21);
        
        [self.contentView addSubview:self.redButton];
        
        
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

CGFloat const kBottomMargin = 10;

- (CGFloat)cellHeightForSubtitleText:(NSString *)text
{
    CGFloat start = CGRectGetMaxY(self.subtitleLabel.frame);
    CGSize subtitleSize = [text sizeWithFont:self.subtitleLabel.font constrainedToSize:CGSizeMake(216, 300) lineBreakMode:UILineBreakModeWordWrap];
    return start + subtitleSize.height + kBottomMargin;
}

@end
