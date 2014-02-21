//
//  HZPersonalBestPopup.m
//  Heyzap
//
//  Created by Daniel Rhodes on 4/2/13.
//
//

#import "HZPersonalBestPopup.h"
#import "HZLeaderboardRank.h"
#import "HZLeaderboardCell.h"
#import "HeyzapSDK.h"
#import "HeyzapSDKPrivate.h"
#import "HZUtils.h"
#import <QuartzCore/QuartzCore.h>
#import "HZAvailability.h"
#import "HZLeaderboardsNetworking.h"
#import "HZDictionaryUtils.h"
#import "HZAnalytics.h"

static HZPersonalBestPopup *hzPersonalBestPopup;

@interface HZPersonalBestPopup()
@property (nonatomic, strong) HZLeaderboardCell *prototypeCell;

@property (nonatomic, strong) UIButton *greenButton;
@property (nonatomic, strong) UIButton *greyButton;
@property (nonatomic, strong) CALayer *footerBorder;

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *closeButtonLine;

@property (nonatomic, strong) UILabel *scoreLabel;
@end

@implementation HZPersonalBestPopup

+ (void)displayPopupWithRank:(HZLeaderboardRank *) rank {
    
    [HZAnalytics logAnalyticsEvent: @"score_overlay_shown_full"];
    
    hzPersonalBestPopup = [[HZPersonalBestPopup alloc] initWithRank: rank];
    [hzPersonalBestPopup show];
}

+ (void) dismissPopup {
    if (hzPersonalBestPopup) {
        [hzPersonalBestPopup removeFromSuperview];
        hzPersonalBestPopup = nil;
    }
}

- (id) initWithRank: (HZLeaderboardRank *) rank {
    self = [super init];
    if (self) {
        self.rank = rank;
        [self setupViews];
        [self setConfiguration: HZTableViewPopupConfigurationStandardFooterWithClose];
        [self.tableView reloadData];
        
        self.headerLabel.text = @"Personal best:";
        self.scoreLabel.text = [[self.rank currentScore] displayScore];
    }
    
    return self;
}

- (void) setupViews {
    self.prototypeCell = [[HZLeaderboardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    self.greenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.greenButton setBackgroundImage:[[HZUtils heyzapBundleImageNamed:@"greenButtonWithInsets0-5-0-5.png"] stretchableImageWithLeftCapWidth:5+3.5 topCapHeight:0] forState:UIControlStateNormal];
    [self.greenButton setBackgroundImage:[[HZUtils heyzapBundleImageNamed:@"greenButtonSelectedWithInsets0-8.5-0-8.5.png"] stretchableImageWithLeftCapWidth:5+3.5 topCapHeight:0] forState:UIControlStateHighlighted];
    [self.greenButton setTitle: @"See Full Leaderboard" forState: UIControlStateNormal];
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
    
    self.scoreLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [self.scoreLabel setTextColor: [UIColor colorWithRed: 178.0/255.0 green: 254.0/255.0 blue: 81.0/255.0 alpha:1.0]];
    [self.scoreLabel setBackgroundColor: [UIColor clearColor]];
    [self.scoreLabel setFont: [UIFont systemFontOfSize: 18.0]];
    [self.scoreLabel setTextAlignment: NSTextAlignmentLeft];
    self.scoreLabel.shadowColor = [UIColor colorWithWhite: 0.0 alpha: 0.5];
    self.scoreLabel.shadowOffset = CGSizeMake(0.0, -0.5);
    self.scoreLabel.layer.masksToBounds = NO;
    self.scoreLabel.adjustsFontSizeToFitWidth = YES;
    self.scoreLabel.minimumFontSize = 14.0;
    self.scoreLabel.lineBreakMode = UILineBreakModeClip;
    [self.header addSubview: self.scoreLabel];
}

#pragma mark - Table View

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *sectionHeader = [[UIView alloc] initWithFrame: CGRectMake(0.0, 0.0, tableView.frame.size.width, 26.0)];
    sectionHeader.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"Heyzap.bundle/bkg-divider.png"]];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(10.0, 0.0 , sectionHeader.frame.size.width - 50.0, 26.0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = [self tableView: tableView titleForHeaderInSection: section];
    titleLabel.textColor = [UIColor colorWithRed: 107.0/255.0 green: 126.0/255.0 blue: 143.0/255.0 alpha: 1.0];
    titleLabel.shadowColor = [UIColor colorWithWhite: 1.0 alpha: 0.5];
    titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    titleLabel.font = [UIFont boldSystemFontOfSize: 14.0];
    [sectionHeader addSubview: titleLabel];
    
    return sectionHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.rank level] name];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25.5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LeaderboardTableViewCell";
    
    HZLeaderboardCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[HZLeaderboardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row < [[self.rank ranks] count]) { //this could get expensive :-(
        NSDictionary *rankData = [[self.rank ranks] objectAtIndex: indexPath.row];
        [self configureCell: cell forRankData: rankData atIndexPath: indexPath];
    } else {
        
    }
    
    return cell;
}

- (void)configureCell:(HZLeaderboardCell *)cell forRankData: (NSDictionary *) rankData atIndexPath:(NSIndexPath *)indexPath {
    
    cell.rankLabel.text = ([[rankData objectForKey: @"rank"] intValue] == 0) ? @"?" : [NSString stringWithFormat: @"%@", [[rankData objectForKey: @"rank"] stringValue]];
    NSURL *imageURL = [NSURL URLWithString: [HZDictionaryUtils hzObjectForKey: @"picture" ofClass: [NSString class] default: @"" withDict: rankData]];
    [cell.userImageView HZsetImageWithURL: imageURL placeholderImage: [UIImage imageNamed: @"Heyzap.bundle/default-user-photo.png"]];
    [cell.displayNameLabel setText: [rankData objectForKey: @"display_name"]];
    [cell.scoreLabel setText: [rankData objectForKey: @"display_score"]];
    [cell.scoreLabel setAdjustsFontSizeToFitWidth: YES];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([[HZDictionaryUtils hzObjectForKey: @"active" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO] withDict: rankData] boolValue]) {
        cell.actualBackgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"Heyzap.bundle/leaderboard_highlight.png"]];
        cell.scoreLabel.font = [UIFont boldSystemFontOfSize: cell.scoreLabel.font.pointSize];
        cell.scoreLabel.shadowOffset = CGSizeMake(0.0, 0.5);
        
        if (!self.rank.loggedIn && [[HZDictionaryUtils hzObjectForKey: @"username" ofClass: [NSString class] default: @"" withDict: rankData] isEqualToString: @""]) {
            cell.actionButton.hidden = NO;
            [cell.actionButton setTitle: @"SAVE" forState: UIControlStateNormal];
            [cell.actionButton addTarget: self action: @selector(didSave:) forControlEvents: UIControlEventTouchUpInside];
        } else {
            cell.actionButton.hidden = YES;
        }
        
        cell.showAccentLines = NO;
    } else {
        cell.scoreLabel.font = [UIFont systemFontOfSize: cell.scoreLabel.font.pointSize];
        cell.scoreLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        cell.actualBackgroundColor = [UIColor clearColor];
        cell.actionButton.hidden = YES;
        cell.showAccentLines = !(indexPath.row == 0);
    }
    
    if (![rankData objectForKey: @"before_active"] && ![rankData objectForKey: @"after_active"]) {
        cell.showGlow = NO;
    } else {
        cell.showGlow = YES;
        cell.glowPosition = [[HZDictionaryUtils hzObjectForKey: @"before_active" ofClass: [NSNumber class] default: [NSNumber numberWithBool: NO] withDict: rankData] boolValue] ? GLOW_BOTTOM : GLOW_TOP;
    }
    
    cell.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:239/255.0f alpha:1];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.rank) {
        return [[self.rank ranks] count];
    }
    
    return 0;
}

#pragma mark - Configuration

- (void)setConfiguration:(HZTableViewPopupConfiguration)configuration
{
    if (configuration == HZTableViewPopupConfigurationTinyFooter) {
        self.tinyFooter = YES;
        self.greenButton.hidden = YES;
        self.greyButton.hidden = YES;
        self.closeButton.hidden = NO;
        self.closeButtonLine.hidden = NO;
    } else if (configuration == HZTableViewPopupConfigurationStandardFooterWithClose) {
        self.tinyFooter = NO;
        self.greenButton.hidden = NO;
        self.greyButton.hidden = YES;
        self.closeButton.hidden = NO;
        self.closeButtonLine.hidden= NO;
        self.aboveFooter.hidden = YES;
    } else {
        self.tinyFooter = NO;
        self.greenButton.hidden = NO;
        self.greyButton.hidden = NO;
        self.closeButton.hidden = YES;
        self.closeButtonLine.hidden = YES;
    }
}

#pragma mark - Orientation

- (void)sizeToFitOrientation:(BOOL)transform
{
    [super sizeToFitOrientation:transform];
    
    self.closeButton.frame = CGRectMake(3, 2, 43.0, 44.0);
    
    
    //    self.closeButton.center = CGPointMake(self.closeButton.center.x, CGRectGetMidY(self.header.frame));
    self.closeButtonLine.frame = CGRectMake(CGRectGetMaxX(self.closeButton.frame), 2, 1.0, 44.0);
    
    //    self.behindTableView.layer.cornerRadius = 7;
    
    self.greenButton.frame = CGRectMake(5, 5+6, 285, 45);
    self.greyButton.frame = CGRectMake(CGRectGetMaxX(self.greenButton.frame)+4, 5+6, 140, 45);
    self.footerBorder.frame = [self CGRectBySettingOrigin: CGPointMake(0, self.footer.layer.cornerRadius) andRect: self.footerBorder.frame];
    
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x-0.5, self.tableView.frame.origin.y+1.0, self.tableView.frame.size.width+1.0, self.tableView.frame.size.height - 1.0);
    
    self.headerLabel.font = [UIFont systemFontOfSize: 18.0];
    self.headerLabel.backgroundColor = [UIColor clearColor];
    self.headerLabel.frame = CGRectMake(55.0, 0, 117.0, 51);
    [self.headerLabel setTextAlignment: NSTextAlignmentLeft];
    self.headerLabel.lineBreakMode = UILineBreakModeClip;
    
//    self.scoreLabel.backgroundColor = [UIColor redColor];
    self.scoreLabel.frame = CGRectMake(self.headerLabel.frame.origin.x + self.headerLabel.frame.size.width, 0.0, 100.0, 51.0);
    
}

#pragma mark - Button Actions

- (void)closeButtonPressed:(id)sender
{
    [self dismissAnimated:YES];
}

- (void)greenButtonPressed:(id)sender
{
    [self dismissAnimated:YES completion:^{
        if (![HeyzapSDK canOpenHeyzap]) {
            NSDictionary *params = @{@"permalink": [[HeyzapSDK sharedSDK] appId],
                                     @"level": [self.rank.level levelID]};
            [HeyzapSDK redirectToWebWithName: @"leaderboard" andParams: params];
        } else {
            [[HeyzapSDK sharedSDK] openLeaderboardLevel: [[self.rank level ] levelID]];
        }
    }];
}

#pragma mark - Footers

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

#pragma mark - CGRect Methods

- (CGRect) CGRectBySettingSize: (CGSize) size andRect: (CGRect) rect {
    return CGRectMake(rect.origin.x, rect.origin.y, size.width, size.height);
}

- (CGRect) CGRectBySettingOrigin: (CGPoint) origin andRect: (CGRect) rect {
    return CGRectMake(origin.x, origin.y, rect.size.width, rect.size.height);
}

#pragma mark - Cell Callbacks

- (void) didSave: (id) sender {
    if (![HeyzapSDK canOpenHeyzap]) {
        NSDictionary *params = @{@"level": [self.rank.level levelID],
                                 @"permalink": [[HeyzapSDK sharedSDK] appId]};

        [HeyzapSDK redirectToWebWithName: @"leaderboard_save" andParams: params];
    } else {
        [[HeyzapSDK sharedSDK] openLeaderboardLevel: [[self.rank level ] levelID]];
    }
}

@end
