//
//  DeviceInfoViewController.m
//  Heyzap
//
//  Created by Maximilian Tagher on 2/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "DeviceInfoViewController.h"
#import <MessageUI/MessageUI.h>
#import "HZDevice.h"

@interface DeviceInfoViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation DeviceInfoViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Device Info";
    }
    return self;
}

#pragma mark - UI Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addDeviceDescriptionLabelsWithInitialY:30];
    
    [self updateScrollViewContentSize];
}

- (void)addDeviceDescriptionLabelsWithInitialY:(CGFloat)initialY
{
    UILabel *idfaLabel = [self deviceInformationLabelWithFrameY:initialY
                                                        keyText:@"IDFA"
                                                      valueText:[[HZDevice currentDevice] HZadvertisingIdentifier]];
    [self.scrollView addSubview:idfaLabel];
    
    UIButton *emailButton = [UIButton buttonWithType:UIButtonTypeSystem];
    emailButton.frame = CGRectMake(idfaLabel.frame.origin.x, CGRectGetMaxY(idfaLabel.frame), 100, 40);
    [emailButton setTitle:@"Email IDFA" forState:UIControlStateNormal];
    [self.scrollView addSubview:emailButton];
    [emailButton addTarget:self
                    action:@selector(emailButtonPressed:)
          forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *appBundleID = [self deviceInformationLabelWithFrameY: CGRectGetMaxY(emailButton.frame)+5
                                                          keyText: @"Bundle ID"
                                                        valueText: [[NSBundle mainBundle] bundleIdentifier]];
    [self.scrollView addSubview: appBundleID];
    
    
}

- (UILabel *)deviceInformationLabelWithFrameY:(CGFloat)y
                                      keyText:(NSString *)keyText
                                    valueText:(NSString *)valueText;
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, y, CGRectGetWidth(self.view.bounds)-5, 25)];
    label.font = [UIFont boldSystemFontOfSize: 13.0];;
    label.textColor = [UIColor colorWithRed: 54.0/255.0 green: 68.0/255.0 blue: 88.0/255.0 alpha: 1.0];
    label.backgroundColor = [UIColor clearColor];
    label.text = [[keyText stringByAppendingString:@": "] stringByAppendingString:valueText];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

# pragma mark - Target Action

- (void)emailButtonPressed:(id)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:@"IDFA"];
        
        [mail setMessageBody:[NSString stringWithFormat:@"Your IDFA is %@",[[HZDevice currentDevice] HZadvertisingIdentifier]]
                      isHTML:NO];
        
        [self presentViewController:mail animated:YES completion:nil];
        
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Can't send mail"
                                    message:@"This device is not setup to deliver email."
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil, nil] show];
    }
}

#pragma mark - MFMailComposeDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end
