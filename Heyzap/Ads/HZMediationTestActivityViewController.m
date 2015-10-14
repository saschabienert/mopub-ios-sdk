//
//  HZMediationTestActivityViewController.m
//  SampleApp
//
//  Created by Monroe Ekilah on 8/9/15.
//  Copyright (c) 2015 heyzap.com. All rights reserved.
//

#import "HZMediationTestActivityViewController.h"
#import <MessageUI/MessageUI.h>
#import "HeyzapMediation.h"
#import "HZUINavigationController.h"
#import "HZNetworkTestActivityViewController.h"

typedef enum {
    kAdUnitSegmentInterstitial,
    kAdUnitSegmentVideo,
    kAdUnitSegmentIncentivized,
    kAdUnitSegmentBanner,
} kAdUnitSegment;


@interface HZMediationTestActivityViewController ()<HZAdsDelegate,UITextFieldDelegate, HZIncentivizedAdDelegate, HZBannerAdDelegate, HZMediationTestSuitePage>

@property (nonatomic, strong) UISegmentedControl *adUnitSegmentedControl;
@property (nonatomic, strong) UITextView *consoleTextView;

@property (nonatomic) UIButton *fetchButton;
@property (nonatomic) UIButton *showButton;
@property (nonatomic) UITextField *adTagField;

@property (nonatomic) UIButton *showBannerButton;
@property (nonatomic) UIButton *hideBannerButton;
@property (nonatomic, strong) HZBannerAd *currentBannerAd;

@property (nonatomic) NSArray *bannerControls;
@property (nonatomic) NSArray *nonBannerControls;

@property (nonatomic) BOOL viewJustLoaded;
@property (nonatomic) BOOL backButtonPressed;

@end

#define ButtonWidth 70
#define ButtonHeight 40
#define ButtonXSpacing 15
#define ButtonYSpacing 10

#define LOG_METHOD_NAME_TO_CONSOLE [self logToConsole:NSStringFromSelector(_cmd)]
#define LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(str) [self logToConsole:[NSString stringWithFormat:@"%@ '%@'", NSStringFromSelector(_cmd), str]]


@interface HZMediationTestActivityViewController ()
@property (nonatomic, weak) id<HZAdsDelegate> previousInterstitialDelegate;
@property (nonatomic, weak) id<HZAdsDelegate> previousVideoDelegate;
@property (nonatomic, weak) id<HZAdsDelegate> previousIncentivizedDelegate;
@property (nonatomic, copy) void (^previousNetworkCallbackBlock)(NSString *network, NSString *callback);

@end

@implementation HZMediationTestActivityViewController


#pragma mark - UI

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self.delegate didLoad:self];
    
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds]; // Set contentSize later dynamically
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Dismisses first responder (keyboard)
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]];
    
    // Setup buttons
    
    CGFloat startHeight = 20;
    
    self.fetchButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.fetchButton.frame = CGRectMake(ButtonXSpacing, startHeight, ButtonWidth, ButtonHeight);
    self.fetchButton.backgroundColor = [UIColor lightTextColor];
    self.fetchButton.layer.cornerRadius = 4.0;
    [self.fetchButton setTitle: @"Fetch" forState: UIControlStateNormal];
    self.fetchButton.accessibilityLabel = @"fetch";
    [self.fetchButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [self.fetchButton addTarget: self action: @selector(fetchAd:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: self.fetchButton];
    
    self.showButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.showButton.frame = CGRectMake(CGRectGetMaxX(self.fetchButton.frame) + ButtonXSpacing, CGRectGetMinY(self.fetchButton.frame), ButtonWidth, ButtonHeight);
    self.showButton.backgroundColor = [UIColor redColor];
    self.showButton.layer.cornerRadius = 4.0;
    [self.showButton setTitle: @"Show" forState: UIControlStateNormal];
    self.showButton.accessibilityLabel = @"show";
    [self.showButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [self.showButton addTarget: self action: @selector(showAd:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: self.showButton];
    
    self.adTagField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.showButton.frame) + ButtonXSpacing, CGRectGetMinY(self.fetchButton.frame), 110.0, ButtonHeight)];
    self.adTagField.delegate = self;
    self.adTagField.borderStyle = UITextBorderStyleRoundedRect;
    self.adTagField.keyboardType = UIKeyboardTypeDefault;
    self.adTagField.placeholder = @"Ad Tag";
    self.adTagField.textAlignment = NSTextAlignmentLeft;
    self.adTagField.accessibilityLabel = @"ad tag";
    [self.adTagField addTarget:self
                        action:@selector(adTagEditingChanged:)
              forControlEvents:UIControlEventEditingChanged];
    
    [self.scrollView addSubview:self.adTagField];
    
    self.hideBannerButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.hideBannerButton.frame = self.fetchButton.frame;
    self.hideBannerButton.backgroundColor = [UIColor darkGrayColor];
    self.hideBannerButton.layer.cornerRadius = 4.0;
    [self.hideBannerButton setTitle: @"Hide" forState: UIControlStateNormal];
    self.hideBannerButton.accessibilityLabel = @"hide";
    [self.hideBannerButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [self.hideBannerButton setTitleColor: [UIColor lightGrayColor] forState: UIControlStateDisabled];
    [self.hideBannerButton addTarget: self action: @selector(hideBannerButtonPressed:) forControlEvents: UIControlEventTouchUpInside];
    self.hideBannerButton.enabled = NO;
    [self.scrollView addSubview: self.hideBannerButton];
    
    self.showBannerButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.showBannerButton.frame = self.showButton.frame;
    self.showBannerButton.backgroundColor = [UIColor greenColor];
    [self.showBannerButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [self.showBannerButton setTitleColor: [UIColor lightGrayColor] forState: UIControlStateDisabled];
    self.showBannerButton.layer.cornerRadius = 4.0;
    [self.showBannerButton setTitle: @"Show" forState: UIControlStateNormal];
    self.showBannerButton.accessibilityLabel = @"show";
    [self.showBannerButton addTarget: self action: @selector(showBannerButtonPressed:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: self.showBannerButton];
    
    UIButton *availableButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(ButtonXSpacing, CGRectGetMaxY(self.fetchButton.frame) + ButtonYSpacing*2, ButtonWidth*1.5, ButtonHeight);
        button.backgroundColor = [UIColor lightTextColor];
        button.layer.cornerRadius = 4.0;
        [button setTitle: @"Ad Available?" forState: UIControlStateNormal];
        [button addTarget: self action: @selector(checkAvailability) forControlEvents: UIControlEventTouchUpInside];
        button;
    });
    [self.scrollView addSubview:availableButton];
    
    UILabel *segmentatonSwitchText = [self switchLabelWithFrameX: (CGRectGetMaxX(availableButton.frame) + ButtonXSpacing) Y:(CGRectGetMinY(availableButton.frame) - ButtonYSpacing*2) text:@"Segmentation"];
    segmentatonSwitchText.frame = CGRectMake(segmentatonSwitchText.frame.origin.x, segmentatonSwitchText.frame.origin.y, 95, segmentatonSwitchText.frame.size.height);
    segmentatonSwitchText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    segmentatonSwitchText.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview: segmentatonSwitchText];
    
    CGFloat switchSize = 40;
    UISwitch *segmentatonSwitch = [[UISwitch alloc] init];
    segmentatonSwitch.frame = CGRectMake(CGRectGetMidX(segmentatonSwitchText.frame) - switchSize/2-5, CGRectGetMaxY(segmentatonSwitchText.frame)-10, switchSize, switchSize);
    segmentatonSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    segmentatonSwitch.on = [[HeyzapMediation sharedInstance] isSegmentationEnabled];
    [segmentatonSwitch addTarget:self action:@selector(segmentationSwitchToggled:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview: segmentatonSwitch];
    
    self.adUnitSegmentedControl = [[UISegmentedControl alloc] initWithItems: @[@"Interstitial", @"Video", @"Incentivized", @"Banner"]];
    self.adUnitSegmentedControl.frame = CGRectMake(ButtonXSpacing, CGRectGetMaxY(availableButton.frame)+ButtonYSpacing, self.view.frame.size.width - ButtonXSpacing*2, ButtonHeight);
    self.adUnitSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.adUnitSegmentedControl setSelectedSegmentIndex: 0];
    [self.adUnitSegmentedControl addTarget:self
                                    action:@selector(changeColorOfShowButton)
                          forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview: self.adUnitSegmentedControl];

    self.consoleTextView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.adUnitSegmentedControl.frame)+10, self.view.frame.size.width, self.view.frame.size.height * 0.4)];
    self.consoleTextView.editable = NO;
    self.consoleTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.consoleTextView setFont: [UIFont fontWithName: @"Courier" size: 12.0]];
    [self.scrollView addSubview:self.consoleTextView];
    
    UIButton *emailConsoleButton = [self buttonWithRect:CGRectMake(ButtonXSpacing, CGRectGetMaxY(self.consoleTextView.frame) + 5, 88, 25) text:@"Email Text"];
    [emailConsoleButton addTarget:self action:@selector(emailConsoleButton) forControlEvents:UIControlEventTouchUpInside];
    emailConsoleButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:emailConsoleButton];
    
    int clearWidth = 50, topWidth = 38, bottomWidth = 63;
    UIButton *clearButton = [self buttonWithRect:CGRectMake(CGRectGetMaxX(self.consoleTextView.frame)-clearWidth, CGRectGetMaxY(self.consoleTextView.frame) + 5, clearWidth, 25) text:@"Clear"];
    [clearButton addTarget:self action:@selector(clearButton) forControlEvents:UIControlEventTouchUpInside];
    clearButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.scrollView addSubview:clearButton];
    
    UIButton *bottomButton = [self buttonWithRect:CGRectMake(CGRectGetMinX(clearButton.frame)-bottomWidth-5, CGRectGetMinY(clearButton.frame), bottomWidth, 25) text:@"Bottom"];
    [bottomButton addTarget:self action:@selector(bottomButton) forControlEvents:UIControlEventTouchUpInside];
    bottomButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.scrollView addSubview:bottomButton];
    
    UIButton *topButton = [self buttonWithRect:CGRectMake(CGRectGetMinX(bottomButton.frame)-topWidth-5, CGRectGetMinY(clearButton.frame), topWidth, 25) text:@"Top"];
    [topButton addTarget:self action:@selector(topButton) forControlEvents:UIControlEventTouchUpInside];
    topButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.scrollView addSubview:topButton];

    
    self.bannerControls = @[self.showBannerButton,self.hideBannerButton];
    self.nonBannerControls = @[self.showButton, self.fetchButton, availableButton];
    [self.bannerControls setValue:@YES forKey:@"hidden"];
    
    // This approach avoids constant manual adjustment
    CGRect subviewContainingRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        subviewContainingRect = CGRectUnion(subviewContainingRect, view.frame);
    }
    self.scrollView.contentSize = (CGSize) { subviewContainingRect.size.width, subviewContainingRect.size.height + 80 };
    
    self.viewJustLoaded = YES;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // self.isMovingFromParentViewController is not true when the back button is pressed for the nav controller
    if (self.isMovingFromParentViewController || self.backButtonPressed) {
        [[HeyzapMediation sharedInstance] setDelegate:self.previousInterstitialDelegate forAdType:HZAdTypeInterstitial];
        [[HeyzapMediation sharedInstance] setDelegate:self.previousVideoDelegate        forAdType:HZAdTypeVideo];
        [[HeyzapMediation sharedInstance] setDelegate:self.previousIncentivizedDelegate forAdType:HZAdTypeIncentivized];
        
        [HeyzapAds networkCallbackWithBlock:self.previousNetworkCallbackBlock];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // self.isMovingToParentViewController is not true when the view is first loaded as the first view in the nav controller
    if (self.isMovingToParentViewController || self.viewJustLoaded) {
        self.viewJustLoaded = NO;
        
        _previousInterstitialDelegate = [[HeyzapMediation sharedInstance] underlyingDelegateForAdType:HZAdTypeInterstitial];
        _previousVideoDelegate        = [[HeyzapMediation sharedInstance] underlyingDelegateForAdType:HZAdTypeVideo];
        _previousIncentivizedDelegate = [[HeyzapMediation sharedInstance] underlyingDelegateForAdType:HZAdTypeIncentivized];
        
        [[HeyzapMediation sharedInstance] setDelegate:self forAdType:HZAdTypeInterstitial];
        [[HeyzapMediation sharedInstance] setDelegate:self forAdType:HZAdTypeVideo];
        [[HeyzapMediation sharedInstance] setDelegate:self forAdType:HZAdTypeIncentivized];
        
        // hijack network callbacks
        self.previousNetworkCallbackBlock = [[HeyzapMediation sharedInstance] networkCallbackBlock];
        [HeyzapAds networkCallbackWithBlock:^(NSString *network, NSString *callback) {
            [self logToConsole:[NSString stringWithFormat:@"Network: %@ callback: %@", network, callback]];
        }];
    }
}

- (UILabel *) switchLabelWithFrameX:(CGFloat)x Y:(CGFloat)y text:(NSString * )text{
    UILabel * label = [[UILabel alloc] initWithFrame: CGRectMake(x,y, 80.0, 40.0)];
    label.text = text;
    label.textColor = [UIColor colorWithRed: 54.0/255.0 green: 68.0/255.0 blue: 88.0/255.0 alpha: 1.0];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize: 14.0];
    return label;
}

- (UIButton * ) buttonWithRect:(CGRect)rect text:(NSString *)text{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:text forState:UIControlStateNormal];
    button.frame = rect;
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
    return button;
}

- (void)viewTapped:(UITapGestureRecognizer *)sender{
    [sender.view endEditing:YES];
}

+(NSDateFormatter *)sharedDateFormatter {
    static NSDateFormatter *sharedDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDateFormatter = [[NSDateFormatter alloc]init];
        [sharedDateFormatter setDateFormat:@"[h:mm:ss a]"];
    });
    
    return sharedDateFormatter;
}

- (void)logToConsole:(NSString *)consoleString {
    self.consoleTextView.text = [self.consoleTextView.text  stringByAppendingFormat:@"\n\n%@ %@",[[[self class] sharedDateFormatter] stringFromDate:[NSDate date]],consoleString];
    [self bottomButton];
}

- (void)adTagEditingChanged:(UITextField *)sender {
    [self changeColorOfShowButton];
}

- (NSString *) adTagText {
    NSString *text = [[self.adTagField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([text isEqualToString:@""]) {
        return nil;
    }
    
    return text;
}

- (void) changeColorOfShowButton {
    [self.bannerControls setValue:@(self.adUnitSegmentedControl.selectedSegmentIndex != kAdUnitSegmentBanner) forKey:@"hidden"];
    [self.nonBannerControls setValue:@(self.adUnitSegmentedControl.selectedSegmentIndex == kAdUnitSegmentBanner) forKey:@"hidden"];
    
    NSString * adTag = [self adTagText];
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            [self setShowButtonOn:[HZInterstitialAd isAvailableForTag:adTag]];
            break;
        case kAdUnitSegmentVideo:
            [self setShowButtonOn:[HZVideoAd isAvailableForTag:adTag]];
            break;
        case kAdUnitSegmentIncentivized:
            [self setShowButtonOn:[HZIncentivizedAd isAvailableForTag:adTag]];
            break;
    }
}

- (void)setShowButtonOn:(BOOL)on
{
    self.showButton.backgroundColor = (on ? [UIColor greenColor] : [UIColor redColor]);
}


#pragma mark - Button handlers

- (void) segmentationSwitchToggled:(UISwitch *)sender {
    [self.view endEditing:YES];
    [[HeyzapMediation sharedInstance] enableSegmentation:sender.isOn];
}

- (void) infoButtonPressed {
    [self.view endEditing:YES];
    
    NSString *msg = @"You can test Heyzap Mediation from this screen. Ad tags you enter on this screen will only be used here. Turning off Segmentation here will also turn it off for your app and the other test suite screens until you turn it back on or restart the app.";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Testing Mediation" message:msg delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void) fetchAd: (id) sender {
    [self.view endEditing:YES];
    
    // use HZShowOptions to format the tag for the log output
    HZShowOptions *options = [HZShowOptions new];
    options.tag = [self adTagText];
    NSString * adTag = options.tag;
    [self logToConsole:[NSString stringWithFormat:@"Fetching for tag: '%@'", adTag]];
    
    void (^completionBlock)(BOOL, NSError *) = ^void(BOOL result, NSError *err) {
        if (result) {
            [self logToConsole:@"Fetch successful."];
        } else {
            [self logToConsole:[NSString stringWithFormat:@"Fetch unsuccessful. Error: %@", err]];
        }
    };
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            [HZInterstitialAd fetchForTag:adTag withCompletion:completionBlock];
            break;
        case kAdUnitSegmentVideo:
            [HZVideoAd fetchForTag:adTag withCompletion:completionBlock];
            break;
        case kAdUnitSegmentIncentivized:
            [HZIncentivizedAd fetchForTag:adTag withCompletion:completionBlock];
            break;
        default:
            break;
    }
}

- (void) showAd: (id) sender {
    [self.view endEditing:YES];
    
    HZShowOptions *options = [[HZShowOptions alloc] init];
    options.viewController = self;
    options.tag = [self adTagText];
    [self logToConsole:[NSString stringWithFormat:@"Showing for tag: '%@'", options.tag]];
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            [HZInterstitialAd showWithOptions:options];
            break;
        case kAdUnitSegmentVideo:
            [HZVideoAd showWithOptions:options];
            break;
        case kAdUnitSegmentIncentivized:
            [HZIncentivizedAd showWithOptions:options];
            break;
        default:
            break;
    }
}

- (void)showBannerButtonPressed:(UIControl *)sender {
    self.showBannerButton.enabled = NO;
    
    [self.view endEditing:YES];
    
    HZBannerAdOptions *opts = [[HZBannerAdOptions alloc] init];
    opts.presentingViewController = self;
    opts.tag = [self adTagText];
    [self logToConsole:[NSString stringWithFormat:@"Attempting to show a banner for tag: '%@'", opts.tag]];
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        opts.admobBannerSize = HZAdMobBannerSizeFlexibleWidthLandscape;
    }
    
    [HZBannerAd placeBannerInView:self.view
                         position:HZBannerPositionBottom
                          options:opts
                          success:^(HZBannerAd *banner) {
                              banner.delegate = self;
                              self.hideBannerButton.enabled = YES;
                              self.currentBannerAd = banner;
                              [self logToConsole:[NSString stringWithFormat:@"Banner shown for tag: '%@'", opts.tag]];
                          } failure:^(NSError *error) {
                              self.showBannerButton.enabled = YES;
                              [self logToConsole:[NSString stringWithFormat:@"Failed to place a banner ad with tag: '%@'. Error: %@", opts.tag, error]];
                          }];
}

- (void)hideBannerButtonPressed:(id)sender {
    [self.view endEditing:YES];
    [self.currentBannerAd removeFromSuperview];
    self.currentBannerAd = nil;
    
    self.hideBannerButton.enabled = NO;
    self.showBannerButton.enabled = YES;
}

- (void) clearButton{
    self.consoleTextView.text = @"";
}

- (void) topButton{
    [self.consoleTextView scrollRangeToVisible:NSMakeRange(0, 0)];
}

- (void) bottomButton{
    [self.consoleTextView scrollRangeToVisible:NSMakeRange(self.consoleTextView.text.length, 0)];
}

- (void) emailConsoleButton{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        [mail setSubject:@"Heyzap SDK Sample App log"];
        
        [mail addAttachmentData:[self.consoleTextView.text dataUsingEncoding:NSUTF8StringEncoding]
                       mimeType:@"text/plain"
                       fileName:@"consoleLog.txt"];
        [self presentViewController:mail animated:YES completion:nil];
        
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Can't send email"
                                    message:@"This device is not setup to deliver email."
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil, nil] show];
    }
}

- (void) showNetworkTestActivity {
    [self.view endEditing:YES];
    HZNetworkTestActivityViewController *vc = [[HZNetworkTestActivityViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)checkAvailability {
    [self.view endEditing:YES];
    
    // use HZShowOptions to format the tag for the log output
    HZShowOptions *options = [HZShowOptions new];
    options.tag = [self adTagText];
    NSString * adTag = options.tag;
    
    NSString *adType;
    BOOL available = NO;
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            available = [HZInterstitialAd isAvailableForTag:adTag];
            adType = @"An interstitial";
            break;
        case kAdUnitSegmentVideo:
            available = [HZVideoAd isAvailableForTag:adTag];
            adType = @"A video";
            break;
        case kAdUnitSegmentIncentivized:
            available = [HZIncentivizedAd isAvailableForTag:adTag];
            adType = @"An incentivized";
            break;
    }
    
    if (adType) {
        [self setShowButtonOn:available];
        [self logToConsole:[NSString stringWithFormat:@"%@ ad %@ available for tag: '%@'.", adType, (available ? @"is" : @"is not"), adTag]];
    }
}

#pragma mark - Callbacks

- (void)didReceiveAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(tag);
    
    [self changeColorOfShowButton];
}
- (void)didShowAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(tag);
    
    [self changeColorOfShowButton];
}
- (void)didClickAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(tag);
}
- (void)didHideAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(tag);
    [self changeColorOfShowButton];
}
- (void)didFailToReceiveAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(tag);
    [self changeColorOfShowButton];
}

- (void)didFailToShowAdWithTag:(NSString *)tag andError:(NSError *)error {
    [self logToConsole:[NSString stringWithFormat:@"%@ tag: %@ error: %@",NSStringFromSelector(_cmd),tag, error]];
    [self changeColorOfShowButton];
}

- (void)willStartAudio {
    LOG_METHOD_NAME_TO_CONSOLE;
}
- (void)didFinishAudio {
    LOG_METHOD_NAME_TO_CONSOLE;
}

- (void)didCompleteAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(tag);
}

- (void) didFailToCompleteAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE_WITH_QUOTED_STRING(tag);
}


#pragma mark - UI Management

- (void)keyboardWillShow:(NSNotification *)notification
{
    // If we're not onscreen, ignore this notification
    if (self.view.superview == nil) {
        return;
    }
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions keyboardCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    
    CGRect keyboardFrameInWindow = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInLocalCoordinates = [self.view convertRect:keyboardFrameInWindow fromView:nil];
    
    [UIView animateWithDuration:animationDuration delay:0 options:keyboardCurve animations:^{
        self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, CGRectGetMinY(keyboardFrameInLocalCoordinates));
    }completion:nil];
}
- (void)keyboardWillHide:(NSNotification *)notification
{
    // If we're not onscreen, ignore this notification
    if (self.view.superview == nil) {
        return;
    }
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions keyboardCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    
    CGRect keyboardFrameInWindow = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInLocalCoordinates = [self.view convertRect:keyboardFrameInWindow fromView:nil];
    
    [UIView animateWithDuration:animationDuration delay:0 options:keyboardCurve animations:^{
        self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, CGRectGetMinY(keyboardFrameInLocalCoordinates));
    }completion:nil];
}

- (void)updateScrollViewContentSize
{
    // This approach avoids constant manual adjustment
    CGRect subviewContainingRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        subviewContainingRect = CGRectUnion(subviewContainingRect, view.frame);
    }
    self.scrollView.contentSize = (CGSize) { CGRectGetWidth(self.view.frame), subviewContainingRect.size.height + 80 };
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UI action methods

- (void) hide {
    self.backButtonPressed = YES;
}

@end
