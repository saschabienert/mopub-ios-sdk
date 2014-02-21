//
//  HZAchievementsTableViewPopup.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZAchievementsTableViewPopup.h"
#import "HZAchievement.h"
#import "HZAchievementTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "HZAvailability.h"
#import "HeyzapSDKPrivate.h"
#import "HeyzapSDK.h"
#import "HZAPIClient.h"
#import "HZAchievementsNetworking.h"
#import "HeyzapSDKPrivate.h"
#import "HZUtils.h"

@interface HZAchievementsTableViewPopup()
// This cell is used to conveniently access the default properties of our table view cells, like font size and such. This simplifies row height calculation. 
@property (nonatomic, strong) HZAchievementTableViewCell *prototypeCell;

@property (nonatomic, strong) UIButton *greenButton;
@property (nonatomic, strong) UIButton *greyButton;
@property (nonatomic, strong) CALayer *footerBorder;

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *closeButtonLine;

@end

@implementation HZAchievementsTableViewPopup

- (id)init
{
    self = [super init];
    if (self) {
        self.prototypeCell = [[HZAchievementTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        self.greenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self.greenButton setBackgroundImage:[[HZUtils heyzapBundleImageNamed:@"greenButtonWithInsets0-5-0-5.png"] stretchableImageWithLeftCapWidth:5+3.5 topCapHeight:0] forState:UIControlStateNormal];
        [self.greenButton setBackgroundImage:[[HZUtils heyzapBundleImageNamed:@"greenButtonSelectedWithInsets0-8.5-0-8.5.png"] stretchableImageWithLeftCapWidth:5+3.5 topCapHeight:0] forState:UIControlStateHighlighted];
        
        if ([HeyzapSDK canOpenHeyzap]) {
            [self.greenButton setTitle:@"See All" forState:UIControlStateNormal];
        } else {
            [self.greenButton setTitle:@"Save" forState:UIControlStateNormal];
        }
        self.greenButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [self.greenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.greenButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.greenButton.titleLabel.layer.shadowOpacity = 0.25f;
        self.greenButton.titleLabel.layer.shadowOffset = CGSizeMake(0, -1);
        self.greenButton.titleLabel.layer.shadowRadius = isRetina() ? 0.5 : 1;
        self.greenButton.titleLabel.layer.masksToBounds = NO;
        
        [self.greenButton addTarget:self action:@selector(greenButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.footer addSubview:self.greenButton];
        
        
        
        self.greyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.greyButton setBackgroundImage:[[HZUtils heyzapBundleImageNamed:@"greyButtonWithCapInsets0-8.5-0-8.5.png"] stretchableImageWithLeftCapWidth:8.5 topCapHeight:0] forState:UIControlStateNormal];
        [self.greyButton setBackgroundImage:[[HZUtils heyzapBundleImageNamed:@"greyButtonSelectedWithCapInsets0-8.5-0-8.5.png"] stretchableImageWithLeftCapWidth:8.5 topCapHeight:0] forState:UIControlStateHighlighted];
        
        [self.greyButton setTitle:@"Close" forState:UIControlStateNormal];
        self.greyButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [self.greyButton setTitleColor:[UIColor colorWithRed:57/255.0f green:57/255.0f blue:57/255.0f alpha:1] forState:UIControlStateNormal];
        
        self.greyButton.titleLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
        self.greyButton.titleLabel.layer.shadowOpacity = 0.75f;
        self.greyButton.titleLabel.layer.shadowRadius = isRetina() ? 0.5f : 1;
        self.greyButton.titleLabel.layer.shadowOffset = CGSizeMake(0, 1);
        self.greyButton.titleLabel.layer.masksToBounds = NO;
        
        [self.greyButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.footer addSubview:self.greyButton];
        
        self.footerBorder = [self footerBorderWithWidth:295];
        [self.footer.layer addSublayer:self.footerBorder];
        
        
        
        self.closeButton = [UIButton buttonWithType: UIButtonTypeCustom];
        [self.closeButton setImage:[HZUtils heyzapBundleImageNamed:@"header_cross.png"] forState:UIControlStateNormal];
        [self.closeButton setBackgroundImage:[HZUtils heyzapBundleImageNamed:@"header_pressedleft.png"] forState: UIControlStateHighlighted];
        [self.closeButton addTarget: self action: @selector(closeButtonPressed:) forControlEvents: UIControlEventTouchUpInside];
        [self.header addSubview:self.closeButton];
        
        self.closeButtonLine = [[UIImageView alloc] initWithImage: [[HZUtils heyzapBundleImageNamed:@"header_line.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
        [self.header addSubview:self.closeButtonLine];
        
        self.closeButton.hidden = YES;
        self.closeButtonLine.hidden = YES;
        
//        self.achievements =  [[NSOrderedSet alloc] initWithArray:@[achievement1, achievement2, achievement3]];
    }
    return self;
}

- (void)setConfiguration:(HZTableViewPopupConfiguration)configuration
{
    if (configuration == HZTableViewPopupConfigurationTinyFooter) {
        self.tinyFooter = YES;
        self.greenButton.hidden = YES;
        self.greyButton.hidden = YES;
        self.closeButton.hidden = NO;
        self.closeButtonLine.hidden = NO;
    } else {
        self.tinyFooter = NO;
        self.greenButton.hidden = NO;
        self.greyButton.hidden = NO;
        self.closeButton.hidden = YES;
        self.closeButtonLine.hidden = YES;
    }
}

- (void)sizeToFitOrientation:(BOOL)transform
{
    [super sizeToFitOrientation:transform];
    
    self.closeButton.frame = CGRectMake(3, 2, 43.0, 44.0);
    
    
//    self.closeButton.center = CGPointMake(self.closeButton.center.x, CGRectGetMidY(self.header.frame));
    self.closeButtonLine.frame = CGRectMake(CGRectGetMaxX(self.closeButton.frame), 2, 1.0, 44.0);

//    self.behindTableView.layer.cornerRadius = 7;
    
    self.greenButton.frame = CGRectMake(5, 5+6, 140, 45);
    self.greyButton.frame = CGRectMake(CGRectGetMaxX(self.greenButton.frame)+4, 5+6, 140, 45);
    self.footerBorder.frame = CGRectBySettingOrigin(self.footerBorder.frame, CGPointMake(0, self.footer.layer.cornerRadius));
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AchievementTableViewCell";
    
    HZAchievementTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[HZAchievementTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (indexPath.row < [self.achievements count]) {
        HZAchievement *achievement = [self.achievements objectAtIndex:indexPath.row];
        [self configureCell:cell forAchievement:achievement atIndexPath:indexPath];
        
    } else {
        
    }
    
    return cell;
}

CGRect CGRectBySettingSize(CGRect rect, CGSize size)
{
    return CGRectMake(rect.origin.x, rect.origin.y, size.width, size.height);
}

CGRect CGRectBySettingOrigin(CGRect rect, CGPoint origin)
{
    return CGRectMake(origin.x, origin.y, rect.size.width, rect.size.height);
}

- (void)configureCell:(HZAchievementTableViewCell *)cell forAchievement:(HZAchievement *)achievement atIndexPath:(NSIndexPath *)indexPath
{
    cell.nameLabel.text = achievement.title;
    
    
    CGSize nameSize = [achievement.title sizeWithFont:cell.nameLabel.font constrainedToSize:CGSizeMake(216, 300) lineBreakMode:UILineBreakModeWordWrap];
    cell.nameLabel.frame = CGRectBySettingSize(cell.nameLabel.frame, nameSize);
    
    cell.subtitleLabel.text = achievement.subtitle;
    
    CGSize subtitleSize = [achievement.subtitle sizeWithFont:cell.subtitleLabel.font constrainedToSize:CGSizeMake(216, 300) lineBreakMode:UILineBreakModeWordWrap];
    cell.subtitleLabel.frame = CGRectBySettingSize(cell.subtitleLabel.frame, subtitleSize);
    
    [cell.badgeImage HZsetImageWithURL:achievement.imageURL];
    
    CGFloat cellHeight = [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
    CGFloat borderHeight = CGRectGetHeight(cell.bottomBorder.frame);
    
    cell.bottomBorder.frame = CGRectMake(cell.bottomBorder.frame.origin.x, cellHeight-borderHeight, cell.bottomBorder.frame.size.width, borderHeight);
    
    cell.redButton.hidden = !achievement.isNew;
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat minimumHeight = 71;
    if (indexPath.row < [self.achievements count]) {
        HZAchievement *achievement = [self.achievements objectAtIndex:indexPath.row];
        CGFloat cellHeightForAchievement = [self.prototypeCell cellHeightForSubtitleText:achievement.subtitle];
        if (cellHeightForAchievement > minimumHeight) {
            return cellHeightForAchievement;
        }
    }
    
    return minimumHeight;
}

- (CALayer *)footerBorderWithWidth:(CGFloat)width
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.achievements count];
}

- (void)closeButtonPressed:(id)sender
{
    [self dismissAnimated:YES];
}

- (void)greenButtonPressed:(id)sender
{
    if ([HeyzapSDK canOpenHeyzap]) {
        [self dismissAnimated:YES completion:^{
            [HZAchievementsNetworking showAllAchievementsWithCompletion:nil];
        }];
    } else {
        [self dismissAnimated:YES completion:^{
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];            
            [HeyzapSDK redirectToWebWithName: @"achievements_save" andParams: params];
        }];
    }
}

@end
