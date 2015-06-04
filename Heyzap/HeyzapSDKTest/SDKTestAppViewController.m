
//
//  HeyzapSDKTestAppViewController.m
//  HeyzapSDKTestApp
//
//  Created by Daniel Rhodes on 8/15/11.
//  Copyright 2011 Heyzap. All rights reserved.
//

#import "SDKTestAppViewController.h"

#import <AdSupport/ASIdentifierManager.h>
#import "HZDevice.h"
#import "HZDictionaryUtils.h"
#import "HZAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import "HZInterstitialAd.h"
#import "HZVideoAd.h"
#import "HZIncentivizedAd.h"
#import <MessageUI/MessageUI.h>
#import "HZNativeAdController.h"
#import "HZNativeAdCollection.h"
#import "HZNativeAd.h"
#import "NativeAdTableViewController.h"
#import "HZBannerAd.h"
#import "HZNoCaretTextField.h"

#import "TestAppPaymentTransactionObserver.h"

#define kTagCreativeIDField 4393

typedef enum {
    kAdUnitSegmentInterstitial,
    kAdUnitSegmentVideo,
    kAdUnitSegmentIncentivized,
    kAdUnitSegmentBanner,
} kAdUnitSegment;

@interface SDKTestAppViewController() <MFMailComposeViewControllerDelegate, HZBannerAdDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UISegmentedControl *creativeSegmentedControl1;
@property (nonatomic, strong) UISegmentedControl *creativeSegmentedControl2;
@property (nonatomic, strong) UISegmentedControl *creativeSegmentedControl3;

@property (nonatomic, strong) UISegmentedControl *adUnitSegmentedControl;

@property (nonatomic, strong) NSString * forcedCreativeType;
@property (nonatomic, strong) NSDictionary * forcedCreativeDict;

@property (nonatomic) UILabel * serverLabel;
@property (nonatomic) UITextField *serverChoice;

@property (nonatomic, strong) UITextView *consoleTextView;

@property (nonatomic, strong) UISwitch * logRequestsSwitch;
@property (nonatomic, strong) UISwitch * logResponsesSwitch;
@property (nonatomic, strong) UISwitch * logCallbacksSwitch;
@property (nonatomic, strong) UISwitch * pauseExpensiveWorkSwitch;
@property (nonatomic, strong) UISwitch * scrollSwitch;

@property (nonatomic, strong) UIButton *showButton;

@property (nonatomic, strong) NSURL *lastFetchURL;

@property (nonatomic, strong) HZBannerAd *wrapper;

@property (nonatomic) UIButton *showBannerButton;
@property (nonatomic) UIButton *hideBannerButton;

@property (nonatomic) NSArray *bannerControls;
@property (nonatomic) NSArray *nonBannerControls;

@property (nonatomic) UITextField *creativeTypeTextField;

@end

@implementation SDKTestAppViewController

- (id) init {
    self = [super init];
    if (self) {
#ifdef MEDIATION
        self.title = @"Mediation";
#else
        self.title = @"Ads";
#endif
    }
    return self;
}

#define LOG_METHOD_NAME_TO_CONSOLE [self logToConsole:NSStringFromSelector(_cmd)]

#pragma mark - Callbacks

- (void)didReceiveAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE;
    
    [self changeColorOfShowButton];
}
- (void)didShowAdWithTag:(NSString *)tag {
    if(self.logCallbacksSwitch.isOn)LOG_METHOD_NAME_TO_CONSOLE;
    
    [self changeColorOfShowButton];
}
- (void)didClickAdWithTag:(NSString *)tag { LOG_METHOD_NAME_TO_CONSOLE;
    
}
- (void)didHideAdWithTag:(NSString *)tag {
    LOG_METHOD_NAME_TO_CONSOLE;
    [self changeColorOfShowButton];
}
- (void)didFailToReceiveAdWithTag:(NSString *)tag { LOG_METHOD_NAME_TO_CONSOLE; }

- (void)didFailToShowAdWithTag:(NSString *)tag andError:(NSError *)error {
    if(self.logCallbacksSwitch.isOn)[self logToConsole:[NSString stringWithFormat:@"%@:%@",NSStringFromSelector(_cmd),error]];
}

- (void)willStartAudio {
    if(self.logCallbacksSwitch.isOn)LOG_METHOD_NAME_TO_CONSOLE;
}
- (void)didFinishAudio {
    if(self.logCallbacksSwitch.isOn)LOG_METHOD_NAME_TO_CONSOLE;
}

- (void)didCompleteAdWithTag:(NSString *)tag { LOG_METHOD_NAME_TO_CONSOLE; }

- (void) didFailToCompleteAdWithTag:(NSString *)tag { LOG_METHOD_NAME_TO_CONSOLE; }

- (void)requestNotification:(NSNotification *)notification{
    if(self.logRequestsSwitch.isOn){
        NSString * logText, *endpoint;
        logText = [[notification.userInfo objectForKey:@"info" ] description];
        endpoint = [notification.userInfo objectForKey:@"endpoint"];
        NSAssert([[NSThread currentThread] isMainThread], @"Request not from main thread");
        [self logToConsole:[NSString stringWithFormat:@"REQUEST - %@: %@",endpoint, logText]];
        
        if ([endpoint isEqualToString: @"fetch_ad"]) {
            NSURL *url = (NSURL*)[notification.userInfo objectForKey: @"url"];
            NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] initWithDictionary: (NSDictionary*)[notification.userInfo objectForKey: @"info"]];
            [requestParams setObject: @"true" forKey: @"output_html"];
            NSString *urlString = [NSString stringWithFormat: @"%@?%@", [url absoluteString], [HZDictionaryUtils hzUrlEncodedStringWithDict: requestParams]];
            self.lastFetchURL = [NSURL URLWithString: urlString];
        }
    }
}

- (void) downloadNotification: (NSNotification *)notification {
    if (self.logRequestsSwitch.isOn) {
        NSURL *url = [notification.userInfo objectForKey: @"url"];
        NSNumber *time = [notification.userInfo objectForKey: @"info"];
        
        [self logToConsole: [NSString stringWithFormat: @"(DOWNLOAD) %@ in %f seconds", [url absoluteString], [time doubleValue]]];
    }
}

- (void) changeColorOfShowButton {
    
    [self.bannerControls setValue:@(self.adUnitSegmentedControl.selectedSegmentIndex != kAdUnitSegmentBanner) forKey:@"hidden"];
    [self.nonBannerControls setValue:@(self.adUnitSegmentedControl.selectedSegmentIndex == kAdUnitSegmentBanner) forKey:@"hidden"];
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            [self setShowButtonOn:[HZInterstitialAd isAvailable]];
            break;
        case kAdUnitSegmentVideo:
            [self setShowButtonOn:[HZVideoAd isAvailable]];
            break;
        case kAdUnitSegmentIncentivized:
            [self setShowButtonOn:[HZIncentivizedAd isAvailable]];
            break;
        default:
            break;
    }
}

- (void)setShowButtonOn:(BOOL)on
{
    self.showButton.backgroundColor = (on ? [UIColor greenColor] : [UIColor redColor]);
}

- (void)responseNotification:(NSNotification *)notification{
    if(self.logResponsesSwitch.isOn){
        NSString * title, * logText;
        if([notification.userInfo objectForKey:@"error_name"]){
            //error notification
            title = @"RESPONSE (FAILED)";
            logText = [[notification.userInfo objectForKey:@"error_info"] description];
        }else{
            title = @"RESPONSE";
            NSMutableDictionary * dict = [[notification userInfo] mutableCopy];
            
            logText = [dict description];
        }
        NSAssert([[NSThread currentThread] isMainThread], @"Response not from main thread");
        [self logToConsole:[NSString stringWithFormat:@"%@: %@",title,logText]];
    }
}


NSString * const kCreativeIDTextFieldAccessibilityLabel = @"creative ID";
NSString * const kShowAdButtonAccessibilityLabel = @"show ad";
NSString * const kFetchAdButtonAccessibilityLabel = @"fetchAd";
NSString * const kViewAccessibilityLabel = @"testAppView";

//these are the same as declred in HZAPIClient.m - included here because we don't want to make them public but need it to work when testing new SDK packages
NSString * const kHZAPIClientDidReceiveResponseNotification = @"HZAPIClientDidReceiveResponse";
NSString * const kHZAPIClientDidSendRequestNotification = @"HZAPIClientDidSendRequest";
NSString * const kHZDownloadHelperSuccessNotification = @"HZDownloadHelperSuccessNotification";

#pragma mark - View lifecycle

const CGFloat kLeftMargin = 10;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [HZInterstitialAd setDelegate:self];
    [HZVideoAd setDelegate:self];
    [HZIncentivizedAd setDelegate:self];
    
    
    [HeyzapAds networkCallbackWithBlock:^(NSString *network, NSString *callback) {
        NSLog(@"Network: %@ Callback: %@", network, callback);
        [self logToConsole: [NSString stringWithFormat: @"[%@] %@", network, callback]];
    }];
    
    self.view.accessibilityLabel = kViewAccessibilityLabel;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestNotification:) name:kHZAPIClientDidSendRequestNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseNotification:) name:kHZAPIClientDidReceiveResponseNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(downloadNotification:) name: kHZDownloadHelperSuccessNotification object: nil];

    
    self.showButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.showButton.frame = CGRectMake(10.0, 10.0, 79.0, 25.0);
    self.showButton.backgroundColor = [UIColor lightTextColor];
    self.showButton.layer.cornerRadius = 4.0;
    [self.showButton setTitle: @"Show" forState: UIControlStateNormal];
    self.showButton.accessibilityLabel = kShowAdButtonAccessibilityLabel;
    [self.showButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [self.showButton addTarget: self action: @selector(showAd:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: self.showButton];
    
    self.showBannerButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = self.showButton.frame;
        button.backgroundColor = [UIColor darkGrayColor];
        button.layer.cornerRadius = 4;
        [button setTitle:@"Show" forState:UIControlStateNormal];
        [button setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [button setTitleColor: [UIColor lightGrayColor] forState: UIControlStateDisabled];
        
        button;
    });
    [self.showBannerButton addTarget:self
                              action:@selector(showBannerButtonPressed:)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.showBannerButton];
    
    [self changeColorOfShowButton];
    
    UIButton *fetchButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    fetchButton.accessibilityLabel = kFetchAdButtonAccessibilityLabel;
    fetchButton.frame = CGRectMake(CGRectGetMaxX(self.showButton.frame) + 10.0, 10.0, 89.0, 25.0);
    fetchButton.backgroundColor = [UIColor lightTextColor];
    fetchButton.layer.cornerRadius = 4.0;
    [fetchButton setTitle: @"Fetch" forState: UIControlStateNormal];
    [fetchButton addTarget: self action: @selector(fetchAd:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: fetchButton];
    
    self.hideBannerButton = ({
        UIButton *button = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        button.frame = fetchButton.frame;
        button.backgroundColor = [UIColor darkGrayColor];
        button.layer.cornerRadius = 4.0;
        [button setTitle: @"Hide" forState: UIControlStateNormal];
        [button setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [button setTitleColor: [UIColor lightGrayColor] forState: UIControlStateDisabled];
        button.enabled = NO;
        button;
    });
    [self.hideBannerButton addTarget: self action: @selector(hideBannerButtonPressed:) forControlEvents: UIControlEventTouchUpInside];
    [self.scrollView addSubview: self.hideBannerButton];
    
    // Keep references to banner/non-banner controls so we can flip between them when the segmented control changes.
    self.bannerControls = @[self.showBannerButton,self.hideBannerButton];
    self.nonBannerControls = @[self.showButton, fetchButton];
    [self.bannerControls setValue:@YES forKey:@"hidden"];
    
    self.adsTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(fetchButton.frame) + 10.0, 10.0, 110.0, 25.5)];
    self.adsTextField.delegate = self;
    self.adsTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.adsTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.adsTextField.placeholder = @"Creative ID";
    self.adsTextField.textAlignment = NSTextAlignmentLeft;
    self.adsTextField.accessibilityLabel = kCreativeIDTextFieldAccessibilityLabel;
    self.adsTextField.tag = kTagCreativeIDField;
    [self.adsTextField addTarget:self
                          action:@selector(creativeIDEditingChanged:)
                forControlEvents:UIControlEventEditingChanged];
    [self.scrollView addSubview:self.adsTextField];
    
    self.creativeTypeTextField = ({
        UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.showButton.frame) + 5, 320, 35)];
        tf.delegate = self;
        tf.borderStyle = UITextBorderStyleRoundedRect;
        tf.textAlignment = NSTextAlignmentCenter;
        
        tf.inputAccessoryView = ({
            UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                           target:nil
                                                                                           action:NULL];
            toolbar.items = @[flexibleSpace, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(creativeTypeDone:)]];
            toolbar;
        });
        
        UIPickerView *picker = ({
            UIPickerView *picker = [[UIPickerView alloc] init];
            picker.delegate = self;
            picker;
        });
        tf.inputView = picker;
        
        tf;
    });
    [self setCreativeTypeTextFieldToNone];
    [self.scrollView addSubview:self.creativeTypeTextField];
    
    UIButton *nativeAdsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nativeAdsButton.frame = CGRectMake(10.0, CGRectGetMaxY(self.creativeTypeTextField.frame) + 10, 120.0, 25.0);
    nativeAdsButton.layer.cornerRadius = 4.0;
    nativeAdsButton.backgroundColor = [UIColor lightTextColor];
    [nativeAdsButton setTitle:@"Show Native Ad" forState:UIControlStateNormal];
    [nativeAdsButton addTarget:self action:@selector(showNativeAds) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:nativeAdsButton];
    
    UIButton *testActivityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    testActivityButton.frame = CGRectMake(CGRectGetMaxX(nativeAdsButton.frame) + 10, CGRectGetMinY(nativeAdsButton.frame), 167.0, 25.0);
    testActivityButton.layer.cornerRadius = 4.0;
    testActivityButton.backgroundColor = [UIColor lightTextColor];
    [testActivityButton setTitle:@"Start Test Suite" forState:UIControlStateNormal];
    [testActivityButton addTarget:self action:@selector(showTestActivity) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:testActivityButton];

    self.adUnitSegmentedControl = [[UISegmentedControl alloc] initWithItems: @[@"Interstitial", @"Video", @"Incentivized", @"Banner"]];
    self.adUnitSegmentedControl.frame = CGRectMake(10, CGRectGetMaxY(nativeAdsButton.frame)+10, self.view.frame.size.width-20, 44);
    self.adUnitSegmentedControl.tag = 3203;
    self.adUnitSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.adUnitSegmentedControl setSelectedSegmentIndex: 0];
    [self.adUnitSegmentedControl addTarget:self
                         action:@selector(changeColorOfShowButton)
               forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview: self.adUnitSegmentedControl];
    
    self.consoleTextView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.adUnitSegmentedControl.frame)+10, self.view.frame.size.width, 180)];
    self.consoleTextView.editable = NO;
    //self.consoleTextView.layer.cornerRadius = 4.0;
    self.consoleTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.consoleTextView setFont: [UIFont fontWithName: @"Courier" size: 12.0]];
    [self.scrollView addSubview:self.consoleTextView];
    
    
    UIButton *emailConsoleButton = [self buttonWithRect:CGRectMake(kLeftMargin, CGRectGetMaxY(self.consoleTextView.frame) + 5, 88, 25) text:@"Email Text"];
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
    

    UILabel *logRequestsSwitchText = [self switchLabelWithFrameX:kLeftMargin Y:CGRectGetMaxY(clearButton.frame) text:@"Requests"];
    logRequestsSwitchText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: logRequestsSwitchText];
    
    
    self.logRequestsSwitch = [[UISwitch alloc] init];
    self.logRequestsSwitch.frame = CGRectMake(kLeftMargin, CGRectGetMaxY(logRequestsSwitchText.frame), 40.0, 40.0);
    self.logRequestsSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: self.logRequestsSwitch];
    
    UILabel *logResponsesSwitchText = [self switchLabelWithFrameX:CGRectGetMaxX(logRequestsSwitchText.frame) + 5 Y: CGRectGetMinY(logRequestsSwitchText.frame) text:@"Responses"];
    logResponsesSwitchText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: logResponsesSwitchText];
    
    self.logResponsesSwitch = [[UISwitch alloc] init];
    self.logResponsesSwitch.frame = CGRectMake(CGRectGetMaxX(logRequestsSwitchText.frame) + 5, CGRectGetMaxY(logResponsesSwitchText.frame), 40.0, 40.0);
    self.logResponsesSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: self.logResponsesSwitch];
    
    
    UILabel *logCallbacksSwitchText = [self switchLabelWithFrameX:CGRectGetMaxX(logResponsesSwitchText.frame) + 5 Y:CGRectGetMinY(logResponsesSwitchText.frame) text:@"Callbacks"];
    logCallbacksSwitchText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: logCallbacksSwitchText];
    
    self.logCallbacksSwitch = [[UISwitch alloc] init];
    self.logCallbacksSwitch.frame = CGRectMake(CGRectGetMinX(logCallbacksSwitchText.frame), CGRectGetMaxY(logResponsesSwitchText.frame), 40.0, 40.0);
    self.logCallbacksSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: self.logCallbacksSwitch];
    
    UILabel *pauseExpensiveWork = [self switchLabelWithFrameX:CGRectGetMinX(self.logRequestsSwitch.frame) + 5 Y:CGRectGetMaxY(self.logRequestsSwitch.frame) + 5 text:@"Pause"];
    pauseExpensiveWork.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: pauseExpensiveWork];
    
    self.pauseExpensiveWorkSwitch = [[UISwitch alloc] init];
    self.pauseExpensiveWorkSwitch.frame = CGRectMake(CGRectGetMinX(logRequestsSwitchText.frame), CGRectGetMaxY(pauseExpensiveWork.frame), 40.0, 40.0);
    self.pauseExpensiveWorkSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.pauseExpensiveWorkSwitch addTarget:self action:@selector(pauseExpensiveWorkSwitchFlipped:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview: self.pauseExpensiveWorkSwitch];
    
    UILabel *scrollSwitchText = [self switchLabelWithFrameX:CGRectGetMinX(logResponsesSwitchText.frame) Y:CGRectGetMaxY(self.logResponsesSwitch.frame) + 5 text:@"Auto Scroll"];
    scrollSwitchText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: scrollSwitchText];
    
    self.scrollSwitch = [[UISwitch alloc] init];
    self.scrollSwitch.frame = CGRectMake(CGRectGetMinX(scrollSwitchText.frame), CGRectGetMaxY(scrollSwitchText.frame), 40.0, 40.0);
    self.scrollSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: self.scrollSwitch];
    
    UILabel *debugModeSwitchText = [self switchLabelWithFrameX:CGRectGetMinX(logCallbacksSwitchText.frame) Y:CGRectGetMaxY(self.logResponsesSwitch.frame) + 5 text:@"Debug"];
    debugModeSwitchText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: debugModeSwitchText];
    
    UISwitch *debugSwitch = [[UISwitch alloc] init];
    debugSwitch.frame = CGRectMake(CGRectGetMinX(debugModeSwitchText.frame), CGRectGetMaxY(debugModeSwitchText.frame) + 5.0, 40.0, 40.0);
    [debugSwitch addTarget: self action: @selector(toggleDebuggable:) forControlEvents: UIControlEventValueChanged];
    [self.scrollView addSubview: debugSwitch];

    self.logCallbacksSwitch.on = self.scrollSwitch.on = YES;
    self.pauseExpensiveWorkSwitch.on = NO;
    
    UIButton *openLastFetchButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [openLastFetchButton setTitle: @"Open Last Fetch in Safari" forState: UIControlStateNormal];
    [openLastFetchButton addTarget: self action: @selector(openLastFetch) forControlEvents: UIControlEventTouchUpInside];
    openLastFetchButton.frame =  CGRectMake(kLeftMargin, CGRectGetMaxY(debugSwitch.frame) + 5.0, 200.0, 50.0);
    [self.scrollView addSubview: openLastFetchButton];
    
    // IAP
    UIButton *makeIAPButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [makeIAPButton setTitle: @"Make IAP" forState: UIControlStateNormal];
    [makeIAPButton addTarget: self action: @selector(makeIAP) forControlEvents: UIControlEventTouchUpInside];
    makeIAPButton.frame = CGRectMake(kLeftMargin, CGRectGetMaxY(openLastFetchButton.frame), 200.0, 50.0);
    [self.scrollView addSubview: makeIAPButton];
    
    // Add to payment queue
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[TestAppPaymentTransactionObserver sharedInstance]];
    
    // Spoof IAP
    UIButton *spoofIAPButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [spoofIAPButton setTitle: @"Spoof IAP" forState: UIControlStateNormal];
    [spoofIAPButton addTarget: self action: @selector(spoofIAP) forControlEvents: UIControlEventTouchUpInside];
    spoofIAPButton.frame = CGRectMake(kLeftMargin, CGRectGetMaxY(makeIAPButton.frame), 200.0, 50.0);
    [self.scrollView addSubview: spoofIAPButton];
    
    // Add to payment queue
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[TestAppPaymentTransactionObserver sharedInstance]];


    // This approach avoids constant manual adjustment
    CGRect subviewContainingRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        subviewContainingRect = CGRectUnion(subviewContainingRect, view.frame);
    }
    self.scrollView.contentSize = (CGSize) { CGRectGetWidth(self.view.frame), subviewContainingRect.size.height + 80 };
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

- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    return YES;
}

- (void) toggleDebuggable: (UISwitch *) sender {
    [HeyzapAds setDebug: sender.on];
}

- (void) setCreativeID: (int) creativeID {
    if (creativeID > 0) {
        [self logToConsole: [NSString stringWithFormat: @"Creative ID set to %i", creativeID]];
    } else {
        [self logToConsole: @"Creative ID cleared"];
    }
    
    [HZIncentivizedAd setCreativeID: creativeID];
    [HZVideoAd setCreativeID: creativeID];
    [HZInterstitialAd setCreativeID: creativeID];
    
    [self changeColorOfShowButton];
}

- (void) fetchAd: (id) sender {
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            [HZInterstitialAd fetch];
            break;
        case kAdUnitSegmentVideo:
            [HZVideoAd fetch];
            break;
        case kAdUnitSegmentIncentivized:
            [HZIncentivizedAd fetch];
            break;
        default:
            break;
    }
}

- (void) showAd: (id) sender {
    [self.view endEditing:YES];
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            NSLog(@"Showing Interstitial");
            [HZInterstitialAd show];
            break;
        case kAdUnitSegmentVideo:
            NSLog(@"Showing Video");
            [HZVideoAd show];
            break;
        case kAdUnitSegmentIncentivized:
            NSLog(@"Showing Incentivized");
            [HZIncentivizedAd show];
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
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        opts.admobBannerSize = HZAdMobBannerSizeFlexibleWidthLandscape;
    }
    
    [HZBannerAd placeBannerInView:self.view
                         position:HZBannerPositionBottom
                          options:opts
     success:^(HZBannerAd *banner) {
         banner.delegate = self;
         self.hideBannerButton.enabled = YES;
         self.wrapper = banner;
     } failure:^(NSError *error) {
         self.showBannerButton.enabled = YES;
     }];
}

- (void)hideBannerButtonPressed:(id)sender {
    [self.view endEditing:YES];
    [self.wrapper removeFromSuperview];
    
    self.hideBannerButton.enabled = NO;
    self.showBannerButton.enabled = YES;
}

#pragma mark - Target-Action

- (void)showNativeAds {
    [HZNativeAdController fetchAds:20 tag:nil completion:^(NSError *error, HZNativeAdCollection *collection) {
        if (error) {
            NSLog(@"error = %@",error);
        } else {
            
            UINavigationController *navController = [[UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
            NativeAdTableViewController *vc = (id)navController.topViewController;
            vc.adCollection = collection;
            [self presentViewController:navController animated:YES completion:nil];
        }
    }];
}

- (void) showTestActivity {
    [HeyzapAds presentMediationDebugViewController];
}

- (void)creativeIDEditingChanged:(UITextField *)sender
{
    [self setCreativeID: [sender.text intValue]];
}

// @[@"Rand", @"PSS",@"SS",@"FI",@"PFI"]
// @[@"I", @"B",@"GOTD", @"SF", @"PSF"]

- (void) setForcedCreativeType:(NSString *)forcedCreativeType{
    _forcedCreativeType = [self.forcedCreativeDict objectForKey:forcedCreativeType];
    [self logToConsole:[NSString stringWithFormat:@"Creative Type: %@", forcedCreativeType]];
}

- (void)creativeControlValueChanged:(UISegmentedControl *)sender
{
    if(sender == self.creativeSegmentedControl1){
        [self.creativeSegmentedControl2 setSelectedSegmentIndex:UISegmentedControlNoSegment];
        [self.creativeSegmentedControl3 setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }else if(sender == self.creativeSegmentedControl2){
        [self.creativeSegmentedControl1 setSelectedSegmentIndex:UISegmentedControlNoSegment];
        [self.creativeSegmentedControl3 setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }else if(sender == self.creativeSegmentedControl3){
        [self.creativeSegmentedControl1 setSelectedSegmentIndex:UISegmentedControlNoSegment];
        [self.creativeSegmentedControl2 setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
    
    NSLog(@"Sender selected index: %ld, title: %@", (long)[sender selectedSegmentIndex], [sender titleForSegmentAtIndex:[sender selectedSegmentIndex]]);
    [self setForcedCreativeType:[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]]];
    
//    [self adsButton:nil];
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
        mail.mailComposeDelegate = self;
        [mail setSubject:@"Heyzap SDK Test App log"];
        
        [mail addAttachmentData:[self.consoleTextView.text dataUsingEncoding:NSUTF8StringEncoding]
                       mimeType:@"text/plain"
                       fileName:@"consoleLog.txt"];
        [self presentViewController:mail animated:YES completion:nil];
        
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Can't send mail"
                                    message:@"This device is not setup to deliver email."
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil, nil] show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void) makeIAP {
    if ([SKPaymentQueue canMakePayments]) {
        SKMutablePayment *payment = [[SKMutablePayment alloc] init];
        payment.productIdentifier = @"com.heyzap.mediationTest.product1";
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        
    } else {
        NSLog(@"Unable to perform IAP");
    }
}

- (void) spoofIAP {
    [HeyzapAds onIAPPurchaseComplete:@"com.heyzap.product" productName:@"Test Product" price:[NSDecimalNumber decimalNumberWithString:@"12.36"]];
}

#pragma mark - Open

- (void) openLastFetch {
    if (self.lastFetchURL != nil) {
        [[UIApplication sharedApplication] openURL: self.lastFetchURL];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Console

- (void)logToConsole:(NSString *)consoleString {
    if (!self.logCallbacksSwitch.isOn) {
        return;
    }
    
    NSDateFormatter * format = [[NSDateFormatter alloc]init];
    [format setDateFormat:@"[h:mm:ss a]"];
    self.consoleTextView.text = [self.consoleTextView.text  stringByAppendingFormat:@"\n\n%@ %@",[format stringFromDate:[NSDate date]],consoleString];
    if (self.scrollSwitch.isOn) {
        [self.consoleTextView scrollRangeToVisible:NSMakeRange(self.consoleTextView.text.length, 0)];
    }
}


#pragma mark - Cleanup

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#undef APPEND_METHOD_NAME_TO_CONSOLE

- (void)bannerDidReceiveAd:(HZBannerAd *)banner {
    NSLog(@"bannerDidReceiveAd");
    LOG_METHOD_NAME_TO_CONSOLE;
    
}

- (void)bannerDidFailToReceiveAd:(HZBannerAd *)banner error:(NSError *)error {
    NSLog(@"bannerDidFailtoReceiveAd:%@",error);
    LOG_METHOD_NAME_TO_CONSOLE;
}

- (void)bannerWasClicked:(HZBannerAd *)banner {
    NSLog(@"bannerWasClicked");
    LOG_METHOD_NAME_TO_CONSOLE;
}

- (void)bannerWillPresentModalView:(HZBannerAd *)banner {
    NSLog(@"bannerWillPresentModalView");
    LOG_METHOD_NAME_TO_CONSOLE;
}

- (void)bannerDidDismissModalView:(HZBannerAd *)banner {
    NSLog(@"bannerDidDismissModalView");
    LOG_METHOD_NAME_TO_CONSOLE;
}

- (void)bannerWillLeaveApplication:(HZBannerAd *)banner {
    NSLog(@"bannerWillLeaveApplication");
    LOG_METHOD_NAME_TO_CONSOLE;
}


#pragma mark - Creative Type support

- (NSArray *)humanizedCreativeTypes {
    return @[@"None",
             @"FullScreenInterstitialCreative",
             @"InterstitialVideoCreative",
             @"LandscapeFullscreenCleanCreative",
             @"LandscapeMultiSwipableCreative",
             @"PortraitCleanCreative",
             @"PortraitFullScreenInterstitialCreative",
             @"PortraitMultiSwipableCreative",
             @"PortraitScreenshotsFullscreenCreative",
             @"ScreenshotsFullscreenCreative",
             ];
}

- (void)creativeTypeDone:(id)sender {
    [self.view endEditing:YES];
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self humanizedCreativeTypes].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self humanizedCreativeTypes][row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row != 0) {
        self.creativeTypeTextField.font = [UIFont systemFontOfSize:18];
        self.creativeTypeTextField.textColor = [UIColor blackColor];
        self.creativeTypeTextField.text = [self humanizedCreativeTypes][row];
    } else {
        [self setCreativeTypeTextFieldToNone];
    }
    
    [HZInterstitialAd setCreativeType: row == 0 ? nil : [self humanizedCreativeTypes][row]];
}

- (void)setCreativeTypeTextFieldToNone {
    self.creativeTypeTextField.font = [UIFont italicSystemFontOfSize:18];
    self.creativeTypeTextField.textColor = [UIColor lightGrayColor];
    self.creativeTypeTextField.text = @"No creative type chosen";
}

- (void)pauseExpensiveWorkSwitchFlipped:(UISwitch *)theSwitch {
    if (theSwitch.isOn) {
        [HeyzapAds pauseExpensiveWork];
    } else {
        [HeyzapAds resumeExpensiveWork];
    }
}


@end
