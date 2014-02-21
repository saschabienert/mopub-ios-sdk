//
//  TestAdViewController.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/7/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "TestAdViewController.h"
#import <Heyzap/Heyzap.h>

@interface TestAdViewController ()
@property (strong, nonatomic) IBOutlet UIButton *showAdButton;
@property (strong, nonatomic) IBOutlet UITextField *creativeIDTextField;

@end

@implementation TestAdViewController

NSString * const kShowAdButtonAccessibilityLabel = @"showAd";
NSString * const kCreativeIDTextFieldAccessibilityLabel = @"creativeID";

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.showAdButton.accessibilityLabel = kShowAdButtonAccessibilityLabel;
    self.creativeIDTextField.accessibilityLabel = kCreativeIDTextFieldAccessibilityLabel;
	// Do any additional setup after loading the view.
}

- (IBAction)showAdPressed:(UIButton *)sender {
    [self.creativeIDTextField resignFirstResponder];
    if (self.creativeIDTextField.text) {
        [HZInterstitialAd showAdWithCreativeID:self.creativeIDTextField.text];
    } else {
        [HZInterstitialAd show];
    }
}

- (IBAction)viewTapped:(id)sender {
    [self.creativeIDTextField resignFirstResponder];
}
@end
