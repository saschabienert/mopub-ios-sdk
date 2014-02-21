//
//  ServerSelectionViewController.m
//  Heyzap
//
//  Created by Maximilian Tagher on 2/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "ServerSelectionViewController.h"
#import "HZAPIClient.h"
#import "HZAdsAPIClient.h"

@interface ServerSelectionViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UISegmentedControl *serverSegmentedControl;
@property (nonatomic) UITextField *ipAddressField;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation ServerSelectionViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Server";
    }
    return self;
}

#pragma mark - UI Setup

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    const CGFloat kLeftMargin = 5;
    
    self.serverSegmentedControl = ({
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Production",@"Stage 1",@"Stage 2", @"localhost",@"IP Address"]];;
        segmentedControl.frame = CGRectMake(kLeftMargin, 20, self.view.frame.size.width-(kLeftMargin * 2), 44);
        segmentedControl.selectedSegmentIndex = 0;
        segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        segmentedControl;
    });
    [self.serverSegmentedControl addTarget:self
                                    action:@selector(serverControlValueChanged:)
                          forControlEvents: UIControlEventValueChanged];
    [self.scrollView addSubview:self.serverSegmentedControl];
    
    
    UILabel *serverDescriptionLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kLeftMargin, CGRectGetMaxY(self.serverSegmentedControl.frame)+5, CGRectGetWidth(self.view.bounds)-(kLeftMargin * 2), 40)];
        label.text = @"To use a local rails server from a device, enter its IP address (OSX: System Prefs > Network)";
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12];
        label.numberOfLines = 2;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 0.5f);
        label;
    });
    [self.scrollView addSubview:serverDescriptionLabel];
    
    
    self.ipAddressField = ({
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(kLeftMargin, CGRectGetMaxY(serverDescriptionLabel.frame)+5, self.view.frame.size.width -(kLeftMargin*2), 30)];
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.placeholder = @"Custom Server URL";
        textField.text = @"http://192.168.1.XXX:3000/";
        textField.returnKeyType = UIReturnKeyDone;
        textField;
    });
    self.ipAddressField.delegate = self;
    [self.ipAddressField addTarget:self
                            action:@selector(ipAddressChanged:)
                  forControlEvents:UIControlEventEditingChanged];
    [self.scrollView addSubview:self.ipAddressField];

    [self updateScrollViewContentSize];
    
    
}

#pragma mark - Target-Action

- (void)ipAddressChanged:(UITextField *)sender
{
    if ([sender.text rangeOfString:@"XXX"].location == NSNotFound && [NSURL URLWithString:sender.text]) {
        self.serverSegmentedControl.selectedSegmentIndex = self.serverSegmentedControl.numberOfSegments - 1;
        [self serverControlValueChanged:self.serverSegmentedControl];
    }
}

- (void)serverControlValueChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0: { [self setBaseURLToString:@"https://ads.heyzap.com/"]; break; }
        case 1: { [self setBaseURLToString:@"http://ads.stage-one.heyzap.com/"]; break; }
        case 2: { [self setBaseURLToString:@"http://ads.stage-two.heyzap.com/"]; break; }
        case 3: { [self setBaseURLToString:@"http://localhost:3000/"]; break; }
        case 4: { [self setBaseURLToString:self.ipAddressField.text]; break; }
    }
    NSArray *const titles = @[@"Production",@"Stage One",@"Stage Two",@"localhost",@"IP"];
    self.title = titles[sender.selectedSegmentIndex];
}

- (void)setBaseURLToString:(NSString *)string
{
    [[HZAPIClient sharedClient] setBaseURL:[NSURL URLWithString:[NSString stringWithString:string]]];
    
    NSString *const fullPath = [string stringByAppendingString:@"in_game_api/ads/"];
    [[HZAdsAPIClient sharedClient] setBaseURL:[NSURL URLWithString:fullPath]];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    return YES;
}

@end
