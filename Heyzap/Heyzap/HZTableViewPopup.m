//
//  HZTableViewPopup.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZTableViewPopup.h"
#import <QuartzCore/QuartzCore.h>
#import "HZAvailability.h"
#import "HZUtils.h"

@interface HZTableViewPopup()

@property (nonatomic, strong) UIImageView *header;
@property (nonatomic, strong) UILabel *headerLabel;
//@property (nonatomic, strong) UIImageView *footer;
@property (nonatomic, strong) CALayer *whiteBorder;


@end

@implementation HZTableViewPopup

- (id)init
{
    self = [super init];
    if (self) {
        self.tableView = [[UITableView alloc] initWithFrame: CGRectZero];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:239/255.0f alpha:1];
        self.tableView.separatorColor = [UIColor clearColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.autoresizesSubviews = NO;
        self.tableView.autoresizingMask = UIViewAutoresizingNone;
        
        self.behindTableView = [[UIView alloc] initWithFrame:CGRectZero];
        self.behindTableView.backgroundColor = [UIColor whiteColor];
        
        self.behindTableView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.behindTableView.layer.shadowOpacity = 0.5f;
        self.behindTableView.layer.shadowRadius = 10;
        self.behindTableView.layer.masksToBounds = NO;
        self.behindTableView.clipsToBounds = NO;
        
        self.behindTableView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.75f].CGColor;
        self.behindTableView.layer.borderWidth = isRetina() ? 0.5 : 1;
        
        [self.contentView addSubview: self.tableView];
        
        [self.contentView insertSubview:self.behindTableView belowSubview:self.tableView];
        
        self.header = [[UIImageView alloc] initWithImage:[HZUtils heyzapBundleImageNamed:@"bkg-popup@2x.png"]];
        self.header.userInteractionEnabled = YES;
        self.headerLabel = [[self class] headerLabelPrototype];
        [self.header addSubview:self.headerLabel];
        [self.contentView addSubview:self.header];
        
        self.footer = [[UIView alloc] init];
        self.footer.backgroundColor = self.tableView.backgroundColor;
        self.footer.layer.cornerRadius = 6;
        
        self.footer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.footer.layer.shadowOpacity = 0.5f;
        self.footer.layer.shadowRadius = 10;
        
        
        self.footer.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.75f].CGColor;
        self.footer.layer.borderWidth = isRetina() ? 0.5 : 1;
        
        
        // I tried to use a CAShapeLayer with a stroke, but it didn't seem to be able to go below 2 pixels in width. 
        self.whiteBorder = [CALayer layer];
        self.whiteBorder.cornerRadius = self.footer.layer.cornerRadius;
        self.whiteBorder.borderColor = [UIColor whiteColor].CGColor;
        self.whiteBorder.borderWidth = isRetina() ? 0.5 : 1;
        [self.footer.layer addSublayer:self.whiteBorder];
        
        [self.contentView insertSubview:self.footer belowSubview:self.tableView];
        
        
        self.aboveFooter = [[UIView alloc] initWithFrame:CGRectZero];
        self.aboveFooter.backgroundColor = [UIColor whiteColor];
        [self.contentView insertSubview:self.aboveFooter aboveSubview:self.footer];
        
    }
    return self;
}

- (void)sizeToFitOrientation:(BOOL)transform
{
    [super sizeToFitOrientation:transform];
    
    
    self.header.frame = CGRectMake(0, 0, 301, 51);
    self.header.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), self.header.center.y);
    
    [self.headerLabel sizeToFit];
    self.headerLabel.center = CGPointMake(CGRectGetMidX(self.header.bounds), CGRectGetMidY(self.header.frame));
    
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.header.frame)-5.5, CGRectGetWidth(self.header.frame)-5-2, 200);
    self.tableView.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), self.tableView.center.y);
    
    self.behindTableView.frame = CGRectMake(self.tableView.frame.origin.x-1, self.tableView.frame.origin.y, self.tableView.frame.size.width+2, self.tableView.frame.size.height+1);
    
    CGFloat cornerRadius = self.footer.layer.cornerRadius;
    self.footer.frame = CGRectMake(2.5, CGRectGetMaxY(self.tableView.frame)-cornerRadius, CGRectGetWidth(self.tableView.frame)+2, 52+cornerRadius);
    
    if (self.tinyFooter) {
        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height+50);
        self.behindTableView.frame = CGRectMake(self.behindTableView.frame.origin.x, self.behindTableView.frame.origin.y, self.behindTableView.frame.size.width, self.behindTableView.frame.size.height+50);
        self.footer.frame = CGRectOffset(self.footer.frame, 0, 2); // was - 48
    }
    
    
    self.footer.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), self.footer.center.y);
    
    self.aboveFooter.frame = CGRectMake(0, CGRectGetMinY(self.footer.frame)-10, CGRectGetWidth(self.footer.frame)-1, cornerRadius+10);
    self.aboveFooter.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), self.aboveFooter.center.y);
    
    self.whiteBorder.frame = CGRectMake(0.5, 0.5, CGRectGetWidth(self.footer.frame)-1, CGRectGetHeight(self.footer.frame)-1);
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RankTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

+ (UILabel *)headerLabelPrototype
{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:18];
    
    // Need CALayer property for shadow radius
    label.layer.shadowColor = [UIColor blackColor].CGColor;
    label.layer.shadowOpacity = 0.25f;
    label.layer.shadowRadius = isRetina() ? 1.0f : 0.5f;
    label.layer.shadowOffset = CGSizeMake(0, -1);
    label.layer.masksToBounds = NO;
    
    return label;
}

@end
