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
#import "PersistentTestAppConfiguration.h"

@interface DeviceInfoViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation DeviceInfoViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Misc";
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
                                                        valueText: [[HZDevice currentDevice] bundleIdentifier]];
    [self.scrollView addSubview: appBundleID];
    
    
    UILabel *const autoPrefetchLabel = ({
        UILabel *label = [self defaultLabelWithFrameY:CGRectGetMaxY(appBundleID.frame)+15];
        [label setText:@"Auto-Prefetch:"];
        [label sizeToFit];
        label;
    });
    [self.scrollView addSubview:autoPrefetchLabel];
    
    UISwitch *const autoPrefetchSwitch = ({
        UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetMaxX(autoPrefetchLabel.frame) + 5, CGRectGetMinY(autoPrefetchLabel.frame), 0, 0)];
        aSwitch.on = [PersistentTestAppConfiguration sharedConfiguration].autoPrefetch;
        [aSwitch addTarget:self
                               action:@selector(autoPrefetchSwitchToggled:)
                     forControlEvents:UIControlEventValueChanged];
        aSwitch;
    });
    [self.scrollView addSubview:autoPrefetchSwitch];
    
    UILabel *chartboostMoreAppsLabel = ({
        UILabel *label = [self defaultLabelWithFrameY: CGRectGetMaxY(autoPrefetchSwitch.frame) + 10.0];
        label.text = @"Chartboost More Apps";
        label.font = [UIFont boldSystemFontOfSize: 13.0];
        label;
    });
    
    [self.scrollView addSubview: chartboostMoreAppsLabel];
    
    UIButton *chartboostMAFetchButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    chartboostMAFetchButton.frame = CGRectMake(5.0, CGRectGetMaxY(chartboostMoreAppsLabel.frame)+5, 100.0, 40.0);
    [chartboostMAFetchButton setTitle: @"Cache" forState: UIControlStateNormal];
    [chartboostMAFetchButton setBackgroundColor: [UIColor lightGrayColor]];
    [chartboostMAFetchButton addTarget: self action: @selector(chartboostMoreAppsCache:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: chartboostMAFetchButton];
    
    UIButton *chartboostMADisplayButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    chartboostMADisplayButton.frame = CGRectMake(CGRectGetMaxX(chartboostMAFetchButton.frame)+5, CGRectGetMaxY(chartboostMoreAppsLabel.frame)+5, 100.0, 40.0);
    [chartboostMADisplayButton setTitle: @"Show" forState: UIControlStateNormal];
    [chartboostMADisplayButton setBackgroundColor: [UIColor lightGrayColor]];
    [chartboostMADisplayButton addTarget: self action: @selector(chartboostMoreAppsDisplay:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: chartboostMADisplayButton];
}

- (void) chartboostMoreAppsCache: (id) sender {
    [Chartboost cacheMoreApps: CBLocationHomeScreen];
}

- (void) chartboostMoreAppsDisplay: (id) sender {
    [Chartboost showMoreApps: CBLocationHomeScreen];
}

- (UILabel *)defaultLabelWithFrameY:(CGFloat)y
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, y, CGRectGetWidth(self.view.bounds)-5, 25)];
    label.font = [UIFont boldSystemFontOfSize: 13.0];;
    label.textColor = [UIColor colorWithRed: 54.0/255.0 green: 68.0/255.0 blue: 88.0/255.0 alpha: 1.0];
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

- (UILabel *)deviceInformationLabelWithFrameY:(CGFloat)y
                                      keyText:(NSString *)keyText
                                    valueText:(NSString *)valueText
{
    UILabel *label = [self defaultLabelWithFrameY:y];
    label.text = [[keyText stringByAppendingString:@": "] stringByAppendingString:valueText];
    return label;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
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

- (void)autoPrefetchSwitchToggled:(UISwitch *)sender {
    [PersistentTestAppConfiguration sharedConfiguration].autoPrefetch = sender.isOn;
}

#pragma mark - MFMailComposeDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end
