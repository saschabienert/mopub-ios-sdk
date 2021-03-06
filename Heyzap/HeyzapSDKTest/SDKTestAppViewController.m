
//
//  HeyzapSDKTestAppViewController.m
//  HeyzapSDKTestApp
//
//  Created by Daniel Rhodes on 8/15/11.
//  Copyright 2011 Heyzap. All rights reserved.
//

@import AVFoundation;
@import CoreLocation;

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
#import "HZMediationSettings.h"
#import "HZHeyzapExchangeAdapter.h"
#import "TestAppPaymentTransactionObserver.h"
#import "HeyzapMediation.h"
#import "SDKTestAppViewControllerAdCallbackDelegate.h"
#import "HZUINavigationController.h"

#import "HZUtils.h"

#import "MediatedNativeAdTableViewController.h"

#define kTagCreativeIDField 4393

typedef enum {
    kAdUnitSegmentInterstitial,
    kAdUnitSegmentVideo,
    kAdUnitSegmentIncentivized,
    kAdUnitSegmentBanner,
} kAdUnitSegment;

@interface SDKTestAppViewController() <MFMailComposeViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, CLLocationManagerDelegate>


@property (nonatomic) SDKTestAppViewControllerHZAdsDelegate *interstitialDelegate;
@property (nonatomic) SDKTestAppViewControllerHZAdsDelegate *videoDelegate;
@property (nonatomic) SDKTestAppViewControllerHZIncentivizedAdDelegate *incentivizedDelegate;
@property (nonatomic) SDKTestAppViewControllerHZBannerAdDelegate *bannerDelegate;

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
@property (nonatomic, strong) UISwitch * musicSwitch;

@property (nonatomic, strong) UIButton *showButton;

@property (nonatomic, strong) NSURL *lastFetchURL;

@property (nonatomic, strong) HZBannerAd *wrapper;

@property (nonatomic) UIButton *showBannerButton;
@property (nonatomic) UIButton *hideBannerButton;
@property (nonatomic) UIButton *destroyBannerButton;

@property (nonatomic) NSArray<UIControl *> *bannerControls;
@property (nonatomic) NSArray<UIControl *> *nonBannerControls;

@property (nonatomic) UITextField *creativeTypeTextField;
@property (nonatomic) UITextField *adTagField;

@property (strong, nonatomic) AVAudioSession *audioSession;
@property (strong, nonatomic) AVAudioPlayer *backgroundMusicPlayer;
@property (nonatomic) BOOL backgroundMusicPlaying;
@property (nonatomic) BOOL backgroundMusicShouldPlay;

@property (nonatomic, readonly) CLLocationManager *manager;

@end

#define METHOD_NAME NSStringFromSelector(_cmd)
#define MERGE_TWO_STRINGS(str1, str2) [NSString stringWithFormat:@"%@ %@", str1, str2]
#define LOG_METHOD_NAME_TO_CONSOLE [self logToConsole:METHOD_NAME]
#define LOG_METHOD_NAME_TO_CONSOLE_WITH_STRING(str) [self logToConsole:MERGE_TWO_STRINGS(METHOD_NAME, str)]


@implementation SDKTestAppViewController

- (id) init {
    self = [super init];
    if (self) {
#ifdef MEDIATION
        self.title = @"Mediation";
#else
        self.title = @"Ads";
#endif
        _manager = [[CLLocationManager alloc] init];
    }
    return self;
}


#pragma mark - Notifications

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

- (void) remoteDataRefreshed: (NSNotification *)notification {
    
    if(self.logCallbacksSwitch.isOn) {
        if([notification.userInfo count] > 0) {
            [self logToConsole: [NSString stringWithFormat:@"Remote data refreshed. Data: %@", [HeyzapAds remoteData]]];
        } else {
            [self logToConsole: [NSString stringWithFormat:@"Remote data refreshed (empty)"]];
        }
    }
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

- (void)paymentTransactionErrorNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:kHZPaymentTransactionErrorNotification] && [notification.object isKindOfClass:[NSError class]]) {
        NSError *error = (NSError *)notification.object;
        
        [[[UIAlertView alloc] initWithTitle:error.domain
                                    message:error.description
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil]
         show];
    }
}


#pragma mark - View lifecycle

NSString * const kCreativeIDTextFieldAccessibilityLabel = @"creative ID";
NSString * const kAdTagTextFieldAccessibilityLabel = @"ad tag";
NSString * const kShowAdButtonAccessibilityLabel = @"show ad";
NSString * const kFetchAdButtonAccessibilityLabel = @"fetchAd";
NSString * const kViewAccessibilityLabel = @"testAppView";

//these are the same as declred in HZAPIClient.m - included here because we don't want to make them public but need it to work when testing new SDK packages
NSString * const kHZAPIClientDidReceiveResponseNotification = @"HZAPIClientDidReceiveResponse";
NSString * const kHZAPIClientDidSendRequestNotification = @"HZAPIClientDidSendRequest";
NSString * const kHZDownloadHelperSuccessNotification = @"HZDownloadHelperSuccessNotification";
NSString * const kHZPaymentTransactionErrorNotification = @"HZPaymentTransactionErrorNotification";

const CGFloat kLeftMargin = 10;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLocationManager];
    
    self.interstitialDelegate = [[SDKTestAppViewControllerHZAdsDelegate alloc] initWthSDKTestAppViewController:self];
    self.interstitialDelegate.name = @"--HZInterstitialAd--";
    self.videoDelegate = [[SDKTestAppViewControllerHZAdsDelegate alloc] initWthSDKTestAppViewController:self];
    self.videoDelegate.name = @"--HZVideoAd--";
    self.incentivizedDelegate = [[SDKTestAppViewControllerHZIncentivizedAdDelegate alloc] initWthSDKTestAppViewController:self];
    self.incentivizedDelegate.name = @"--HZIncentivizedAd--";
    self.bannerDelegate = [[SDKTestAppViewControllerHZBannerAdDelegate alloc] initWthSDKTestAppViewController:self];
    self.bannerDelegate.name = @"--HZBannerAd--";
    
    [HZInterstitialAd setDelegate:self.interstitialDelegate];
    [HZVideoAd setDelegate:self.videoDelegate];
    [HZIncentivizedAd setDelegate:self.incentivizedDelegate];
    
    
    [HeyzapAds networkCallbackWithBlock:^(NSString *network, NSString *callback) {
        NSLog(@"Network: %@ Callback: %@", network, callback);
        [self logToConsole: [NSString stringWithFormat: @"[%@] %@", network, callback]];
        // wait a bit to change show button color for SDK to process whatever changed
        [self changeColorOfShowButtonAfterSeconds:0.1];
    }];
    
    self.view.accessibilityLabel = kViewAccessibilityLabel;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestNotification:) name:kHZAPIClientDidSendRequestNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseNotification:) name:kHZAPIClientDidReceiveResponseNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadNotification:) name:kHZDownloadHelperSuccessNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteDataRefreshed:) name:HZRemoteDataRefreshedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paymentTransactionErrorNotification:) name:kHZPaymentTransactionErrorNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adAudioStarted) name:HZMediationWillStartAdAudioNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adAudioEnded) name:HZMediationDidFinishAdAudioNotification object:nil];

    
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
    
    self.destroyBannerButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(CGRectGetMaxX(fetchButton.frame) + 10.0, 10.0, CGRectGetWidth(self.hideBannerButton.frame), CGRectGetHeight(self.hideBannerButton.frame));
        button.backgroundColor = [UIColor darkGrayColor];
        button.layer.cornerRadius = 4.0;
        [button setTitle: @"Destroy" forState: UIControlStateNormal];
        [button setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [button setTitleColor: [UIColor lightGrayColor] forState: UIControlStateDisabled];
        button.enabled = NO;
        [button addTarget: self action: @selector(destroyBannerButtonPressed) forControlEvents: UIControlEventTouchUpInside];
        button;
    });
    [self.scrollView addSubview:self.destroyBannerButton];
    
    UIButton *availableButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = self.destroyBannerButton.frame;
        button.backgroundColor = [UIColor lightTextColor];
        button.layer.cornerRadius = 4.0;
        [button setTitle: @"Available?" forState: UIControlStateNormal];
        [button addTarget: self action: @selector(checkAvailability) forControlEvents: UIControlEventTouchUpInside];
        button;
    });
    [self.scrollView addSubview:availableButton];
    
    // Keep references to banner/non-banner controls so we can flip between them when the segmented control changes.
    self.bannerControls = @[self.showBannerButton, self.hideBannerButton, self.destroyBannerButton];
    self.nonBannerControls = @[self.showButton, fetchButton, availableButton];
    [self.bannerControls setValue:@YES forKey:@"hidden"];
    
    self.creativeTypeTextField = ({
        UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.showButton.frame) + 5, 180, 35)];
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
    
    self.adTagField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(fetchButton.frame) + 10.0, CGRectGetMaxY(availableButton.frame) + 10.0, 110.0, 25.5)];
    self.adTagField.delegate = self;
    self.adTagField.borderStyle = UITextBorderStyleRoundedRect;
    self.adTagField.keyboardType = UIKeyboardTypeAlphabet;
    self.adTagField.placeholder = @"Ad Tag";
    self.adTagField.textAlignment = NSTextAlignmentLeft;
    self.adTagField.accessibilityLabel = kAdTagTextFieldAccessibilityLabel;
    self.adTagField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.adTagField addTarget:self
                        action:@selector(adTagEditingChanged:)
              forControlEvents:UIControlEventEditingChanged];
    
    [self.scrollView addSubview:self.adTagField];
    
    self.adsTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.adTagField.frame) + 10.0, CGRectGetMinY(self.adTagField.frame), 110.0, 25.5)];
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

    
    UIButton *nativeAdsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nativeAdsButton.frame = CGRectMake(10.0, CGRectGetMaxY(self.creativeTypeTextField.frame) + 10, 100.0, 25.0);
    nativeAdsButton.layer.cornerRadius = 4.0;
    nativeAdsButton.backgroundColor = [UIColor lightTextColor];
    [nativeAdsButton setTitle:@"HZ Native" forState:UIControlStateNormal];
    [nativeAdsButton addTarget:self action:@selector(showNativeAds) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:nativeAdsButton];
    
    UIButton *mediatedNativeAdsButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(CGRectGetMaxX(nativeAdsButton.frame) + 10, CGRectGetMaxY(self.creativeTypeTextField.frame) + 10, 100.0, 25.0);
        button.layer.cornerRadius = 4.0;
        button.backgroundColor = [UIColor lightTextColor];
        [button setTitle:@"Med Native" forState:UIControlStateNormal];
        [button addTarget:self
                   action:@selector(showMediatedNativeAds)
         forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.scrollView addSubview:mediatedNativeAdsButton];
    
    
    UIButton *testActivityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    testActivityButton.frame = CGRectMake(CGRectGetMaxX(mediatedNativeAdsButton.frame) + 10, CGRectGetMinY(nativeAdsButton.frame), 137.0, 25.0);
    testActivityButton.layer.cornerRadius = 4.0;
    testActivityButton.backgroundColor = [UIColor lightTextColor];
    [testActivityButton setTitle:@"Test Suite" forState:UIControlStateNormal];
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
    
    UILabel *musicLabel = [self switchLabelWithFrameX:CGRectGetMinX(self.pauseExpensiveWorkSwitch.frame) + 5 Y:CGRectGetMaxY(self.pauseExpensiveWorkSwitch.frame) + 5 text:@"BG Music"];
    pauseExpensiveWork.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview: musicLabel];
    
    self.musicSwitch = [[UISwitch alloc] init];
    self.musicSwitch.frame = CGRectMake(CGRectGetMinX(self.pauseExpensiveWorkSwitch.frame), CGRectGetMaxY(musicLabel.frame), 40.0, 40.0);
    self.musicSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.musicSwitch addTarget:self action:@selector(musicSwitchFlipped:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview: self.musicSwitch];
    
    UIButton *openLastFetchButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [openLastFetchButton setTitle: @"Open Last Fetch in Safari" forState: UIControlStateNormal];
    [openLastFetchButton addTarget: self action: @selector(openLastFetch) forControlEvents: UIControlEventTouchUpInside];
    openLastFetchButton.frame =  CGRectMake(kLeftMargin, CGRectGetMaxY(self.musicSwitch.frame) + 5.0, 200.0, 50.0);
    [self.scrollView addSubview: openLastFetchButton];
    
    // IAP
    UIButton *makeIAPButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [makeIAPButton setTitle: @"Make IAP" forState: UIControlStateNormal];
    [makeIAPButton addTarget: self action: @selector(makeIAP) forControlEvents: UIControlEventTouchUpInside];
    makeIAPButton.frame = CGRectMake(kLeftMargin, CGRectGetMaxY(openLastFetchButton.frame), 200.0, 50.0);
    [self.scrollView addSubview: makeIAPButton];
    
    // Spoof IAP
    UIButton *spoofIAPButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [spoofIAPButton setTitle: @"Spoof IAP" forState: UIControlStateNormal];
    [spoofIAPButton addTarget: self action: @selector(spoofIAP) forControlEvents: UIControlEventTouchUpInside];
    spoofIAPButton.frame = CGRectMake(kLeftMargin, CGRectGetMaxY(makeIAPButton.frame), 200.0, 50.0);
    [self.scrollView addSubview: spoofIAPButton];
    
    // Clear Incentivized Daily Limit counter
    UIButton *clearIncentivizedCountButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [clearIncentivizedCountButton setTitle: @"Clear Incentivized Count" forState: UIControlStateNormal];
    [clearIncentivizedCountButton addTarget: self action: @selector(clearIncentivizedCount) forControlEvents: UIControlEventTouchUpInside];
    clearIncentivizedCountButton.frame = CGRectMake(kLeftMargin, CGRectGetMaxY(spoofIAPButton.frame), 200.0, 50.0);
    [self.scrollView addSubview: clearIncentivizedCountButton];
    
    // Clear Impression History db (used for Segmentation)
    UIButton *clearImpressionHistoryButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    [clearImpressionHistoryButton setTitle: @"Clear Impression History" forState: UIControlStateNormal];
    [clearImpressionHistoryButton addTarget: self action: @selector(clearImpressionHistory) forControlEvents: UIControlEventTouchUpInside];
    clearImpressionHistoryButton.frame = CGRectMake(kLeftMargin, CGRectGetMaxY(clearIncentivizedCountButton.frame), 200.0, 50.0);
    [self.scrollView addSubview: clearImpressionHistoryButton];
    
    // Add to payment queue
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[TestAppPaymentTransactionObserver sharedInstance]];


    // This approach avoids constant manual adjustment
    CGRect subviewContainingRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        subviewContainingRect = CGRectUnion(subviewContainingRect, view.frame);
    }
    self.scrollView.contentSize = (CGSize) { subviewContainingRect.size.width, subviewContainingRect.size.height + 80 };
    
    
    // Audio
    [self configureAudioSession];
    [self configureAudioPlayer];
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

#pragma mark - Button/UI handlers

- (void) changeColorOfShowButtonAfterSeconds:(NSTimeInterval)seconds {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * seconds), dispatch_get_main_queue(), ^{
        [self changeColorOfShowButton];
    });
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
        default:
            break;
    }
}

- (void)setShowButtonOn:(BOOL)on
{
    self.showButton.backgroundColor = (on ? [UIColor greenColor] : [UIColor redColor]);
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
    // use HZShowOptions to format the tag for the log output
    HZShowOptions *options = [HZShowOptions new];
    options.tag = [self adTagText];
    NSString * adTagText = options.tag;
    
    [self logToConsole:[NSString stringWithFormat:@"Fetching for tag: '%@'", adTagText]];
    
    void (^completion)(BOOL, NSError *) = ^void (BOOL result, NSError *error){
        if (!result || error) {
            [self logToConsole:[NSString stringWithFormat:@"Fetch ad completion block - failed. Error: %@", error.localizedDescription]];
        } else {
            [self logToConsole:@"Fetch ad completion block - success"];
        }
    };
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            [HZInterstitialAd fetchForTag:adTagText withCompletion:completion];
            break;
        case kAdUnitSegmentVideo:
            [HZVideoAd fetchForTag:adTagText withCompletion:completion];
            break;
        case kAdUnitSegmentIncentivized:
            [HZIncentivizedAd fetchForTag:adTagText withCompletion:completion];
            break;
        default:
            break;
    }
}

- (void) showAd: (id) sender {
    [self.view endEditing:YES];

    HZShowOptions *opts = [[HZShowOptions alloc] init];
    opts.tag = [self adTagText];
    opts.completion = ^(BOOL success, NSError *err) {
        [self logToConsole:[NSString stringWithFormat:@"Show completion block. Success=%x, err=%@", success, err]];
    };
    
    [self logToConsole:[NSString stringWithFormat:@"Showing for tag: '%@'", opts.tag]];
    
    switch (self.adUnitSegmentedControl.selectedSegmentIndex) {
        case kAdUnitSegmentInterstitial:
            NSLog(@"Showing Interstitial");
            [HZInterstitialAd showWithOptions:opts];
            break;
        case kAdUnitSegmentVideo:
            NSLog(@"Showing Video");
            [HZVideoAd showWithOptions:opts];
            break;
        case kAdUnitSegmentIncentivized:
            NSLog(@"Showing Incentivized");
            opts.incentivizedInfo = @"test app incentivized info";
            [HZIncentivizedAd showWithOptions:opts];
            break;
        default:
            break;
    }
}

- (void)checkAvailability {
    // use HZShowOptions to format the tag for the log output
    HZShowOptions *options = [HZShowOptions new];
    options.tag = [self adTagText];
    NSString * adTag = options.tag;
    
    NSString *adType;
    BOOL available;
    
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
        default:
            break;
    }
    
    if (adType) {
        [self setShowButtonOn:available];
        [self logToConsole:[NSString stringWithFormat:@"%@ ad %@ available for tag: '%@'.", adType, (available ? @"is" : @"is not"), adTag]];
    } else {
        [self logToConsole:@"Is Available Error: Unable to determine ad type."];
    }
}

- (void)showBannerButtonPressed:(UIControl *)sender {
    self.showBannerButton.enabled = NO;
    
    [self.view endEditing:YES];
    
    HZBannerAdOptions *opts = [[HZBannerAdOptions alloc] init];
    opts.tag = [self adTagText];
    opts.presentingViewController = self;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        opts.admobBannerSize = HZAdMobBannerSizeFlexibleWidthLandscape;
    }
    opts.fetchTimeout = 45;
    
    [HZBannerAd placeBannerInView:self.view
                         position:HZBannerPositionBottom
                          options:opts
                          success:^(HZBannerAd *banner) {
                              banner.delegate = self.bannerDelegate;
                              self.wrapper = banner;
                              [self setBannerButtonStates];
                          } failure:^(NSError *error) {
                              NSString *errorMessage = @"Failed to fetch banner";
                              if (error.localizedDescription) {
                                  errorMessage = [errorMessage stringByAppendingFormat:@"; error was: %@",error.localizedDescription];
                                  [self logToConsole:errorMessage];
                              }
                              
                              [self setBannerButtonStates];
                          }];
}

- (void)hideBannerButtonPressed:(id)sender {
    [self.view endEditing:YES];
    [self.wrapper setHidden:!self.wrapper.hidden];
    [self setBannerButtonStates];
}

- (void)destroyBannerButtonPressed {
    [self.view endEditing:YES];
    [self.wrapper removeFromSuperview];
    self.wrapper = nil;
    
    [self setBannerButtonStates];
}

- (void) setBannerButtonStates {
    self.hideBannerButton.enabled = (self.wrapper != nil);
    self.destroyBannerButton.enabled = (self.wrapper != nil);
    self.showBannerButton.enabled = (self.wrapper == nil);
    [self.hideBannerButton setTitle:(self.wrapper && self.wrapper.hidden ? @"Unhide" : @"Hide") forState:UIControlStateNormal];
}

- (void)showNativeAds {
    [HZNativeAdController fetchAds:20 tag:nil completion:^(NSError *error, HZNativeAdCollection *collection) {
        if (error) {
            NSLog(@"error = %@",error);
        } else {
            
            HZUINavigationController *navController = [[UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
            navController.orientationMask = UIInterfaceOrientationMaskAll;
            
            NativeAdTableViewController *vc = (id)navController.topViewController;
            vc.adCollection = collection;
            [self presentViewController:navController animated:YES completion:nil];
        }
    }];
}

- (void)showMediatedNativeAds {
    MediatedNativeAdTableViewController *tvc = [[MediatedNativeAdTableViewController alloc] initWithTag:[self adTagText]];
    HZUINavigationController *navController = [[HZUINavigationController alloc] initWithRootViewController:tvc orientations:UIInterfaceOrientationMaskAll];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void) showTestActivity {
    [HeyzapAds presentMediationDebugViewController];
}

- (void)creativeIDEditingChanged:(UITextField *)sender {
    [self setCreativeID: [sender.text intValue]];
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

- (void) clearButton{
    self.consoleTextView.text = @"";
}

- (void) topButton{
    [self.consoleTextView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void) bottomButton{
    CGRect rect = CGRectMake(0, self.consoleTextView.contentSize.height -1, self.consoleTextView.frame.size.width, self.consoleTextView.contentSize.height);
    [self.consoleTextView scrollRectToVisible:rect animated:NO];
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
        [self logToConsole:@"IAP made."];
    } else {
        NSLog(@"Unable to perform IAP");
    }
}

- (void) spoofIAP {
    [HeyzapAds onIAPPurchaseComplete:@"com.heyzap.product" productName:@"Test Product" price:[NSDecimalNumber decimalNumberWithString:@"12.36"]];
    [self logToConsole:@"IAP spoofed."];
}

- (void) clearIncentivizedCount {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHZMediationUserDefaultsKeyIncentivizedCounter];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHZMediationUserDefaultsKeyIncentivizedDate];
    [self logToConsole:@"Incentivized daily limit counter cleared."];
}

- (void) clearImpressionHistory {
    [[[HeyzapMediation sharedInstance] segmentationController] clearImpressionHistoryWithCompletion:^(BOOL successful){
        [self logToConsole:[NSString stringWithFormat:@"Impression history delete was %@successful.", (successful ? @"" : @"NOT ")]];
        [self changeColorOfShowButtonAfterSeconds:0.5];
    }] ;
    
}

- (void)pauseExpensiveWorkSwitchFlipped:(UISwitch *)theSwitch {
    if (theSwitch.isOn) {
        [HeyzapAds pauseExpensiveWork];
    } else {
        [HeyzapAds resumeExpensiveWork];
    }
}


#pragma mark - Open

- (void) openLastFetch {
    if (self.lastFetchURL != nil) {
        [[UIApplication sharedApplication] openURL: self.lastFetchURL];
    }
}


#pragma mark Orientation

- (BOOL)shouldAutorotate {
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Console

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
    if (!self.logCallbacksSwitch.isOn) {
        return;
    }
    
    self.consoleTextView.text = [self.consoleTextView.text  stringByAppendingFormat:@"\n\n%@ %@",[[[self class] sharedDateFormatter] stringFromDate:[NSDate date]],consoleString];
    if (self.scrollSwitch.isOn) {
        // get around weird bug in iOS 9 - text view scrolling has issues when done directly after updating the text
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self bottomButton];
        });
    }
}

- (void) logCallback:(NSString *)callbackName {
    [self logToConsole:callbackName];
    [self changeColorOfShowButton];
}
- (void) logCallback:(NSString *)callbackName withString:(NSString *)string {
    [self logToConsole:[NSString stringWithFormat:@"%@ %@", callbackName, string]];
    [self changeColorOfShowButton];
}


#pragma mark - Cleanup

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Legacy Creative Type support

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
    self.creativeTypeTextField.text = @"Creative type";
}


#pragma mark - Audio

- (void) configureAudioSession {
    self.audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    [self.audioSession setCategory:AVAudioSessionCategoryAmbient error:&setCategoryError];
    if (setCategoryError) {
        NSLog(@"Error setting audio session category! code:%ld error: %@", (long)[setCategoryError code], setCategoryError);
    }
}

- (void)configureAudioPlayer {
    NSURL *backgroundMusicURL = [[NSBundle mainBundle] URLForResource:@"elevator_music" withExtension:@"mp3"];
    // On Max's machine the URL is non-deterministically nil, causing a crash. Since this is not crucial functionality we just don't play music in that case.
    if (backgroundMusicURL) {
        self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:nil];
        self.backgroundMusicPlayer.numberOfLoops = -1;	// loop forever
        [self.backgroundMusicPlayer prepareToPlay];
    }
}

- (void)tryPlayMusic {
    if (self.backgroundMusicPlaying) {
        return;
    }
    [self.backgroundMusicPlayer prepareToPlay];
    [self.backgroundMusicPlayer play];
    self.backgroundMusicPlaying = YES;
}

- (void) tryPauseMusic {
    if (self.backgroundMusicPlaying) {
        [self.backgroundMusicPlayer pause];
        self.backgroundMusicPlaying = NO;
    }
}

- (void) musicSwitchFlipped:(UISwitch *)sender {
    self.backgroundMusicShouldPlay = sender.isOn;
    if (sender.isOn) {
        [self tryPlayMusic];
    } else {
        [self tryPauseMusic];
    }
}

- (void) adAudioStarted {
    [self otherAudioIsPlaying:YES];
}
- (void) adAudioEnded {
    [self otherAudioIsPlaying:NO];
}
- (void) otherAudioIsPlaying:(BOOL)isPlaying {
    if (self.backgroundMusicShouldPlay) {
        if (isPlaying) {
            [self tryPauseMusic];
        } else {
            [self tryPlayMusic];
        }
    }
}

#pragma mark - Location

- (void)setupLocationManager {
    self.manager.delegate = self;
    self.manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.manager.distanceFilter = 500; // meters
    
    if ([self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.manager requestWhenInUseAuthorization];
    } else {
        [self.manager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self.manager startUpdatingLocation];
    } else {
        [self.manager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *latestLocation = locations.lastObject;
    HZDemographics *demographics = [HeyzapAds demographicInformation];
    demographics.location = latestLocation;
}

@end
