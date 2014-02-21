//
//  HZAchievementTableViewCell.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import <UIKit/UIKit.h>
#import "HZImageView.h"

@interface HZAchievementTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) HZImageView *badgeImage;
@property (nonatomic, strong) CALayer *bottomBorder;
@property (nonatomic, strong) UIImageView *redButton;

- (CGFloat)cellHeightForSubtitleText:(NSString *)text;

@end
