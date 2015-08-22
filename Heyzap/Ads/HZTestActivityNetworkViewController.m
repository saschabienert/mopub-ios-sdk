/*
 * Copyright (c) 2014, Smart Balloon, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of 'Smart Balloon, Inc.' nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "HZTestActivityNetworkViewController.h"
#import "HeyzapAds.h"
#import "HeyzapMediation.h"
#import "HZMediationAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZDispatch.h"
#import "HZUnityAds.h"
#import "HZDevice.h"
#import "HZBannerAd.h"
#import "HZMediationConstants.h"
#import "HZBannerAdOptions_Private.h"
#import "HZNoCaretTextField.h"
#import "HZBannerAd.h"

#import "HZFacebookAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZHeyzapExchangeAdapter.h"

@interface HZTestActivityNetworkViewController() <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, HZBannerAdDelegate, HZIncentivizedAdDelegate>

@property (nonatomic) HZBaseAdapter *network;
@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) BOOL available;
@property (nonatomic) BOOL initialized;
@property (nonatomic) BOOL enabled;
@property (nonatomic) UIView *adControls;
@property (nonatomic) NSString *currentAdFormat;
@property (nonatomic) HZAdType currentAdType;
@property (nonatomic) UIButton *showButton;
@property (nonatomic) UILabel *availableStatus;
@property (nonatomic) UILabel *initializationStatus;
@property (nonatomic) UILabel *enabledStatus;
@property (nonatomic) UITextView *debugLog;

@property (nonatomic) UIButton *showBannerButton;
@property (nonatomic) UIButton *hideBannerButton;

@property (nonatomic) UIPickerView *bannerPositionPickerView;
@property (nonatomic) UIPickerView *bannerSizePickerView;

@property (nonatomic) UITextField *bannerPositionTextField;
@property (nonatomic) UITextField *bannerSizeTextField;

@property (nonatomic) HZBannerPosition chosenBannerPosition;
@property (nonatomic) NSValue *chosenBannerSize;

@property (nonatomic) NSArray *nonBannerControls;
@property (nonatomic) NSArray *bannerControls;

@property (nonatomic) HZBannerAd *bannerWrapper;

NSValue *hzBannerPositionValue(HZBannerPosition position);
HZBannerPosition hzBannerPositionFromNSValue(NSValue *value);
NSString *hzBannerPositionName(HZBannerPosition position);

@property (nonatomic, weak) id<HZAdsDelegate> previousInterstitialDelegate;
@property (nonatomic, weak) id<HZAdsDelegate> previousVideoDelegate;
@property (nonatomic, weak) id<HZAdsDelegate> previousIncentivizedDelegate;


@end

@implementation HZTestActivityNetworkViewController

#pragma mark - Initialization

- (instancetype) initWithNetwork:(HZBaseAdapter *)network rootVC:(UIViewController *)rootVC available:(BOOL)available initialized:(BOOL)initialized enabled:(BOOL)enabled {
    self = [super init];

    self.network = network;
    self.rootVC = rootVC;
    self.available = available;
    self.initialized = initialized;
    self.enabled = enabled;
    
    // set this adapter's delegate to us so we can get callbacks
    
    _previousInterstitialDelegate = [[HeyzapMediation sharedInstance] underlyingDelegateForAdType:HZAdTypeInterstitial];
    _previousVideoDelegate        = [[HeyzapMediation sharedInstance] underlyingDelegateForAdType:HZAdTypeVideo];
    _previousIncentivizedDelegate = [[HeyzapMediation sharedInstance] underlyingDelegateForAdType:HZAdTypeIncentivized];
    
    [[HeyzapMediation sharedInstance] setDelegate:self forAdType:HZAdTypeInterstitial];
    [[HeyzapMediation sharedInstance] setDelegate:self forAdType:HZAdTypeVideo];
    [[HeyzapMediation sharedInstance] setDelegate:self forAdType:HZAdTypeIncentivized];
    
    // UnityAds starts with a view controller that is not us, need to set it since AppLovin apparently jacks it
    if ([[network name] isEqualToString:@"unityads"]) {
        [[HZUnityAds sharedInstance] setViewController:self];
    }
    
    return self;
}

#pragma mark - View lifecycle methods

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeTop;
    }

    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = [[self.network class] humanizedName];
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
    [self.navigationItem setRightBarButtonItem:refresh];
    
    [self.view addSubview:[self makeView]];
    [self showOrHideBannerControls];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        [[HeyzapMediation sharedInstance] setDelegate:self.previousInterstitialDelegate forAdType:HZAdTypeInterstitial];
        [[HeyzapMediation sharedInstance] setDelegate:self.previousVideoDelegate        forAdType:HZAdTypeVideo];
        [[HeyzapMediation sharedInstance] setDelegate:self.previousIncentivizedDelegate forAdType:HZAdTypeIncentivized];
    }
}

- (void)setChosenBannerPosition:(HZBannerPosition)chosenBannerPosition {
    _chosenBannerPosition = chosenBannerPosition;
    
    self.bannerPositionTextField.text = [@"Position: " stringByAppendingString:hzBannerPositionName(chosenBannerPosition)];
}

- (void)setChosenBannerSize:(NSValue *)chosenBannerSize {
    _chosenBannerSize = chosenBannerSize;
    self.bannerSizeTextField.text = [@"Size: " stringByAppendingString:[self bannerSizeDescription:chosenBannerSize]];
}

#pragma mark - UI action methods

- (void) refresh {
    // check available
    self.available = [[self.network class] isSDKAvailable];
    
    // hit the /info endpoint for enabled status and initialization credentials
    [[HZMediationAPIClient sharedClient] GET:@"info" parameters:nil success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json];
        NSArray *thisNetworkArray = [networks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *mediator, NSDictionary *bindings) {
            return [mediator[@"name"] isEqualToString:[[self.network class] name]];
        }]];
        
        // for whatever reason, sometimes /info doesn't always give disabled networks, in that case don't change anything
        if(thisNetworkArray.count == 1){
            NSDictionary *network = thisNetworkArray[0];

            // check enabled
            self.enabled = [network[@"enabled"] boolValue];

            // check original initialization succeeded
            if ([[HeyzapMediation sharedInstance] isAdapterInitialized:self.network]) {
                self.initialized = YES;
            } else {
                self.initialized = NO;
            }

            // if credentials have changed, pop an alert
            if (![self.network.credentials isEqualToDictionary:network[@"data"]]) {
                [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ credentials have changed", [[self.network class] humanizedName]]
                                            message:@"Restart the app to verify SDK initialization" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }

            HZDLog(@"Available: %d", self.available);
            HZDLog(@"Initialized: %d", self.initialized);
            HZDLog(@"Enabled: %d", self.enabled);
            
            // update the checks and crosses
            [self setStatusForLabel:self.availableStatus withBool:self.available];
            [self setStatusForLabel:self.initializationStatus withBool:self.initialized];
            [self setStatusForLabel:self.enabledStatus withBool:self.enabled];
            
            // display or remove the ad controls
            if (self.available && self.initialized) {
                
                [self hideBanner];
                
                UIView *const previousSuperview = self.adControls.superview;
                
                [self.adControls removeFromSuperview];
                self.adControls = [self makeAdControls];
                [previousSuperview addSubview:self.adControls];
            } else {
                [self.adControls removeFromSuperview];
            }
            [self showOrHideBannerControls];
        }
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        HZDLog(@"Error from /info: %@", error.localizedDescription);
    }];
}

- (void) switchAdFormat:(UISegmentedControl *)adFormatControl {
    self.currentAdFormat = [[adFormatControl titleForSegmentAtIndex:adFormatControl.selectedSegmentIndex ] lowercaseString];
    self.currentAdType = [self adTypeWithString:self.currentAdFormat];
    HZDLog(@"Current ad format: %@", self.currentAdFormat);
    
    [self showOrHideBannerControls];
    
    if (self.currentAdType != HZAdTypeBanner) {
        [self changeShowButtonColor];
        [self hideBanner];
    }
}

- (void)showOrHideBannerControls {
    [self.bannerControls setValue:@(self.currentAdType != HZAdTypeBanner) forKey:@"hidden"];
    [self.nonBannerControls setValue:@(self.currentAdType == HZAdTypeBanner) forKey:@"hidden"];
    
    if ([[self bannerSizes] count] == 0) {
        self.bannerSizeTextField.hidden = YES;
    }
    
    if (self.currentAdType != HZAdTypeBanner) {
        [self.view endEditing:YES]; // Dismisses picker views when you change to a non-banner format.
    }
}

- (void) fetchAd {
    // monroe: this won't work with creativeType - switch it to check if at least one of the supported creativeTypes from the adType has credentials, warn on the others / if none do
//    if (![self.network hasCredentialsForAdType:self.currentAdType]) {
//        [self appendStringToDebugLog:@"This network doesn't have credentials for this ad type. Make sure you've added credentials on the Heyzap dashboard."];
//        return;
//    }
    
    [self appendStringToDebugLog:@"Fetching ad (may take up to 10 seconds)"];
    NSDictionary *additionalParams = @{ @"network": [[self.network class] name] };
    [[HeyzapMediation sharedInstance] fetchForAdType:self.currentAdType tag:nil additionalParams:additionalParams completion:^(BOOL result, NSError *error) {
        if (error) {
            [self appendStringToDebugLog:@"Fetch failed"];
        } else {
            [self appendStringToDebugLog:@"Fetch succeeded"];
        }

        [self changeShowButtonColor];
    }];
}

- (void) showAd {
    [self appendStringToDebugLog:@"Showing ad"];
    NSDictionary *additionalParams = @{ @"network": [[self.network class] name] };

    HZShowOptions *options = [HZShowOptions new];
    options.viewController = self;
    options.completion = ^(BOOL result, NSError *error) {
        if (error) {
            NSString *const errorMessage = ({
                NSString *msg = @"Show failed";
                if (error.localizedDescription) {
                    msg = [msg stringByAppendingFormat:@": %@",error.localizedDescription];
                }
                msg;
            });
            
            [self appendStringToDebugLog:errorMessage];
        } else {
            [self appendStringToDebugLog:@"Show succeeded"];
        }

        [self changeShowButtonColor];
    };

    [[HeyzapMediation sharedInstance] showAdForAdUnitType:self.currentAdType additionalParams:additionalParams options:options];
}

#pragma mark - HZAdDelegate methods

- (void)didShowAdWithTag: (NSString *) tag {
    [self logCallback:_cmd];
}

- (void)didFailToShowAdWithTag: (NSString *) tag andError: (NSError *)error {
    [self changeShowButtonColor];
    [self logCallback:_cmd];
}

- (void)didReceiveAdWithTag: (NSString *) tag {
    [self logCallback:_cmd];
}

- (void)didFailToReceiveAdWithTag: (NSString *) tag {
    [self logCallback:_cmd];
}

- (void)didClickAdWithTag: (NSString *) tag {
    [self logCallback:_cmd];
}

- (void)didHideAdWithTag: (NSString *) tag {
    [self changeShowButtonColor];
    [self logCallback:_cmd];
}

- (void)willStartAudio {
    [self logCallback:_cmd];
}

- (void) didFinishAudio {
    [self logCallback:_cmd];
}

- (void)didCompleteAdWithTag: (NSString *) tag {
    [self logCallback:_cmd];
}

- (void)didFailToCompleteAdWithTag: (NSString *) tag {
    [self logCallback:_cmd];
}

- (void)logCallback:(SEL)selector {
    [self appendStringToDebugLog:[NSString stringWithFormat:@"Ad Callback: %@",NSStringFromSelector(selector)]];
}


#pragma mark - View creation utility methods

- (UIView *) makeView {
    // top level view
    UIView *currentNetworkView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,30,
                                                                CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view;
    });
    
    // sdk available label
    UIView *availableView = [self makeStatusLabel:@"available" withStatus:self.available text:@"SDK Available" y:95];
    [currentNetworkView addSubview:availableView];
    
    // sdk initialization succeeded label
    UIView *initializationView = [self makeStatusLabel:@"initialization" withStatus:self.initialized text:@"SDK initialized with credentials" y:availableView.frame.origin.y + 15];
    [currentNetworkView addSubview:initializationView];

    // network is enabled label
    UIView *enabledView = [self makeStatusLabel:@"enabled" withStatus:self.enabled text:@"Network enabled on dashboard" y:initializationView.frame.origin.y + 15];
    [currentNetworkView addSubview:enabledView];
    
    // only show ad fetching/showing controls and debug log if the network was initialized correctly
    if(self.available && self.initialized){
        self.adControls = [self makeAdControls];
        [currentNetworkView addSubview:self.adControls];

        // debug log
        self.debugLog = ({
            UITextView *text = [[UITextView alloc] initWithFrame:CGRectMake(self.adControls.frame.origin.x, self.adControls.frame.origin.y + self.adControls.frame.size.height,
                                                                            self.adControls.frame.size.width, 210)];
            text.editable = false;
            text.font = [UIFont fontWithName: @"Courier" size: 12.0];
            text.text = @"Debug log:";
            text;
        });
        
        UIView *debugLogShadow = ({
            UIView *view = [[UIView alloc] initWithFrame:self.debugLog.frame];
            view.layer.shadowColor = [UIColor grayColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(0, 1);
            view.layer.shadowOpacity = 1;
            view.layer.shadowRadius = 1;
            view.layer.masksToBounds = NO;
            view.backgroundColor = [UIColor whiteColor];
            view;
        });
        
        [currentNetworkView addSubview:debugLogShadow];
        [currentNetworkView addSubview:self.debugLog];
    }
    
    return currentNetworkView;
}

- (UIView *) makeAdControls {
    UIView *adControls = ({
        UIView *controls = [[UIView alloc] initWithFrame:CGRectMake(10, 160, self.view.frame.size.width - 20, 190)];
        controls.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        controls;
    });
    
    // setup currentAdFormat and currentAdType
    HZAdType supportedAdFormats = [self.network possibleSupportedAdTypes];
    NSMutableArray *formats = [[NSMutableArray alloc] init];
    if(supportedAdFormats & HZAdTypeInterstitial){
        [formats addObject:@"Interstitial"];
    }
    if(supportedAdFormats & HZAdTypeVideo){
        [formats addObject:@"Video"];
    }
    if(supportedAdFormats & HZAdTypeIncentivized){
        [formats addObject:@"Incentivized"];
    }
    if (supportedAdFormats & HZAdTypeBanner) {
        [formats addObject:@"Banner"];
    }
    self.currentAdFormat = [[formats objectAtIndex:0] lowercaseString];
    self.currentAdType = [self adTypeWithString:self.currentAdFormat];
    HZDLog(@"Current ad format: %@", self.currentAdFormat);
    
    // segmented control for supported ad formats
    UISegmentedControl *adFormatControl = ({
        UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:formats];
        control.frame = CGRectMake(0, 0, adControls.frame.size.width, 40);
        control.selectedSegmentIndex = 0;
        control;
    });
    [adFormatControl addTarget:self action:@selector(switchAdFormat:) forControlEvents:UIControlEventValueChanged];
    [adControls addSubview:adFormatControl];
    
    const CGFloat buttonWidth = adFormatControl.frame.size.width / 2.0 - 5;
    const CGRect leftButtonFrame = CGRectMake(adFormatControl.frame.origin.x, adFormatControl.frame.origin.y + adFormatControl.frame.size.height + 10, buttonWidth, 40);
    const CGRect rightButtonFrame = CGRectMake(CGRectGetMaxX(leftButtonFrame) + 10, leftButtonFrame.origin.y, buttonWidth, 40);
    
    // buttons for fetch and show
    UIButton *fetchButton = ({
        UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor darkGrayColor]];
        button.frame = leftButtonFrame;
        [button setTitle:@"Fetch" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(fetchAd) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [adControls addSubview:fetchButton];
    
    self.showButton = ({
        UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor redColor]];
        button.frame = rightButtonFrame;
        [button setTitle:@"Show" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showAd) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [adControls addSubview:self.showButton];
    
    self.nonBannerControls = @[fetchButton, self.showButton];
    
    if ([self showBanners]) {
        
        self.hideBannerButton = ({
            UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor darkGrayColor]];
            button.enabled = NO;
            button.frame = leftButtonFrame;
            [button setTitle:@"Hide" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            [button addTarget:self action:@selector(hideBanner:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [adControls addSubview:self.hideBannerButton];
        
        self.showBannerButton = ({
            UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor darkGrayColor]];
            button.frame = rightButtonFrame;
            [button setTitle:@"Show" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            [button addTarget:self action:@selector(showBanner:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [adControls addSubview:self.showBannerButton];
        
        
        const CGFloat positionY = CGRectGetMaxY(fetchButton.frame) + 10;
        
        self.bannerPositionTextField = ({
            HZNoCaretTextField *textField = [[HZNoCaretTextField alloc] initWithFrame:CGRectMake(adFormatControl.frame.origin.x, positionY, buttonWidth, 40)];
            textField.delegate = self;
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.textAlignment = NSTextAlignmentCenter;
            
            textField.inputAccessoryView = ({
                UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
                UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                               target:nil
                                                                                               action:NULL];
                toolbar.items = @[flexibleSpace, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                       target:self
                                                                                                       action:@selector(bannerPositionPickerDone:)]];
                toolbar;
            });
            
            UIPickerView *picker = ({
                UIPickerView *picker = [[UIPickerView alloc] init];
                picker.delegate = self;
                picker;
            });
            textField.inputView = picker;
            self.bannerPositionPickerView = picker;
            
            textField;
        });
        
        self.bannerSizeTextField = ({
            HZNoCaretTextField *textField = [[HZNoCaretTextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.showButton.frame), positionY, buttonWidth, 40)];
            textField.delegate = self;
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.textAlignment = NSTextAlignmentCenter;
            
            textField.inputAccessoryView = ({
                UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
                UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                               target:nil
                                                                                               action:NULL];
                toolbar.items = @[flexibleSpace, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(bannerSizePickerDone:)]];
                toolbar;
            });
            
            UIPickerView *picker = ({
                UIPickerView *picker = [[UIPickerView alloc] init];
                picker.delegate = self;
                picker;
            });
            textField.inputView = picker;
            self.bannerSizePickerView = picker;
            
            textField;
        });
        
        
        [adControls addSubview:self.bannerPositionTextField];
        [adControls addSubview:self.bannerSizeTextField];
        
        
        self.bannerControls = @[self.hideBannerButton, self.showBannerButton, self.bannerPositionTextField, self.bannerSizeTextField];
    }
    
    if ([self showBanners]) {
        self.chosenBannerPosition = HZBannerPositionTop;
        self.chosenBannerSize = [self bannerSizes].firstObject;
    }
    
    return adControls;
}

+ (UIButton *)buttonWithBackgroundColor:(UIColor *)color {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.backgroundColor = color;
    button.layer.cornerRadius = 3.0;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return button;
}

- (UIView *) makeStatusLabel:(NSString *)type withStatus:(BOOL)status text:(NSString *)text y:(CGFloat)y {
    UIView *wrapperView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x + 10, y, self.view.frame.size.width - 20, 30)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    UILabel *textLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(wrapperView.frame.origin.x + 10, wrapperView.frame.origin.y - 125,
                                                                   wrapperView.frame.size.width - 20, wrapperView.frame.size.height)];
        label.text = text;
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [wrapperView addSubview:textLabel];
    
    UILabel *statusLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(wrapperView.frame.origin.x - 10, textLabel.frame.origin.y,
                                                                   20, textLabel.frame.size.height)];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [self setStatusForLabel:statusLabel withBool:status];
    [wrapperView addSubview:statusLabel];

    if ([type isEqualToString:@"available"]) {
        self.availableStatus = statusLabel;
    } else if ([type isEqualToString:@"initialization"]) {
        self.initializationStatus = statusLabel;
    } else if ([type isEqualToString:@"enabled"]) {
        self.enabledStatus = statusLabel;
    }
    
    return wrapperView;
}

- (void) setStatusForLabel:(UILabel  *)label withBool:(BOOL)status {
    if (status) {
        label.text = @"☑︎";
        label.textColor = [UIColor greenColor];
    } else {
        label.text = @"☒";
        label.textColor = [UIColor redColor];
    }
}

#pragma mark - General utility methods

- (HZAdType) adTypeWithString:(NSString *)string {
    HZAdType adType = 0;
    
    if([string isEqualToString:@"interstitial"]){
        adType = HZAdTypeInterstitial;
    } else if([string isEqualToString:@"video"]){
        adType = HZAdTypeVideo;
    } else if([string isEqualToString:@"incentivized"]){
        adType = HZAdTypeIncentivized;
    } else if ([string isEqualToString:@"banner"]) {
        adType = HZAdTypeBanner;
    }
    
    return adType;
}

- (void) changeShowButtonColor {
    const BOOL available = [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:self.currentAdType tag:[HeyzapAds defaultTagName] network:self.network];
    if (available) {
        self.showButton.backgroundColor = [UIColor greenColor];
    } else {
        self.showButton.backgroundColor = [UIColor redColor];
    }
}

- (void) appendStringToDebugLog:(NSString *)string {
    self.debugLog.text = [NSString stringWithFormat:@"%@\n%@", self.debugLog.text, string];
    NSRange bottom = NSMakeRange(self.debugLog.text.length, 0);
    [self.debugLog scrollRangeToVisible:bottom];
}

#pragma mark - UIPickerViewDelegate (Banners)

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == self.bannerPositionPickerView) {
        return 2;
    } else if (pickerView == self.bannerSizePickerView) {
        return [[self bannerSizes] count];
    } else {
        NSLog(@"Unknown picker view!!");
        return 0;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == self.bannerPositionPickerView) {
        
        return [[self class] bannerPositionNames][row];
        
    } else if (pickerView == self.bannerSizePickerView) {
        
        NSValue *value = [self bannerSizes][row];
        return [self bannerSizeDescription:value];
        
    } else {
        NSLog(@"Unknown picker view!!");
        return nil;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == self.bannerPositionPickerView) {
        
        
        NSValue *value = [[self class] bannerPositions][row];
        self.chosenBannerPosition = hzBannerPositionFromNSValue(value);
        
    } else if (pickerView == self.bannerSizePickerView) {
        self.chosenBannerSize = [self bannerSizes][row];
    }
}

- (void)bannerPositionPickerDone:(UIBarButtonItem *)sender {
    [self.bannerPositionTextField resignFirstResponder];
}

- (void)bannerSizePickerDone:(UIBarButtonItem *)sender {
    [self.bannerSizeTextField resignFirstResponder];
}

+ (NSArray *)bannerPositionNames {
    return @[
             hzBannerPositionName(HZBannerPositionTop),
             hzBannerPositionName(HZBannerPositionBottom),
             ];
}

NSString *hzBannerPositionName(HZBannerPosition position) {
    switch (position) {
        case HZBannerPositionTop: {
            return @"Top";
        }
        case HZBannerPositionBottom: {
            return @"Bottom";
        }
    }
}

+ (NSArray *)bannerPositions {
    return @[
             hzBannerPositionValue(HZBannerPositionTop),
             hzBannerPositionValue(HZBannerPositionBottom),
             ];
    
}

NSValue *hzBannerPositionValue(HZBannerPosition position) {
    return [NSValue valueWithBytes:&position objCType:@encode(HZBannerPosition)];
}

HZBannerPosition hzBannerPositionFromNSValue(NSValue *value) {
    HZBannerPosition position;
    [value getValue:&position];
    return position;
}

- (NSString *)bannerSizeDescription:(NSValue *)value {
    if ([self.network.name isEqualToString:[HZFacebookAdapter name]]) {
        HZFacebookBannerSize size = hzFacebookBannerSizeFromValue(value);
        return hzFacebookBannerSizeDescription(size);
    } else if ([self.network.name isEqualToString: [HZAdMobAdapter name]]) {
        HZAdMobBannerSize size = hzAdMobBannerSizeFromValue(value);
        return hzAdMobBannerSizeDescription(size);
    } else {
        return @"n/a";
    }
}

- (NSArray *)bannerSizes {
    NSString *name = [self.network name];
    if ([name isEqualToString:[HZFacebookAdapter name]]) {
        return [HZBannerAdOptions facebookBannerSizes];
    } else if ([name isEqualToString:[HZAdMobAdapter name]]) {
        return [HZBannerAdOptions admobBannerSizes];
    } else {
        return @[];
    }
}

- (BOOL)showBanners {
    return [self.network supportsCreativeType:HZCreativeTypeBanner];
}

- (HZBannerAdOptions *)bannerOptions {
    HZBannerAdOptions *opts = [[HZBannerAdOptions alloc] init];
    
    opts.networkName = self.network.name;
    
    opts.presentingViewController = self;
    
    if ([self.network.name isEqualToString: [HZFacebookAdapter name]]) {
        opts.facebookBannerSize = hzFacebookBannerSizeFromValue(self.chosenBannerSize);
    } else if ([self.network.name isEqualToString: [HZAdMobAdapter name]]) {
        opts.admobBannerSize = hzAdMobBannerSizeFromValue(self.chosenBannerSize);
    }
    
    return opts;
}

- (void)showBanner:(UIButton *)sender {
    [self.view endEditing:YES];
    sender.enabled = NO;
    
    [self appendStringToDebugLog:@"Requesting Banner..."];
    
    [HZBannerAd placeBannerInView:self.view
                                position:self.chosenBannerPosition
                                 options:[self bannerOptions]
     success:^(HZBannerAd *banner) {
         [self appendStringToDebugLog:@"Showing banner"];
         self.hideBannerButton.enabled = YES;
         self.bannerWrapper = banner;
         self.bannerWrapper.delegate = self;
     } failure:^(NSError *error) {
         sender.enabled = YES;
         [self appendStringToDebugLog:@"Error getting banner!"];
     }];
     
}

- (void)hideBanner:(UIButton *)sender {
    [self.view endEditing:YES];
    [self hideBanner];
}

- (void)hideBanner {
    [self.bannerWrapper removeFromSuperview];
    self.bannerWrapper = nil;
    
    self.hideBannerButton.enabled = NO;
    self.showBannerButton.enabled = YES;
}

#pragma mark - Banner Ad Delegate

- (void)bannerDidReceiveAd:(HZBannerAd *)banner {
    [self logBannerCallback:_cmd];
}
- (void)bannerDidFailToReceiveAd:(HZBannerAd *)banner error:(NSError *)error {
    [self logBannerCallback:_cmd];
}
- (void)bannerWasClicked:(HZBannerAd *)banner {
    [self logBannerCallback:_cmd];
}
- (void)bannerWillPresentModalView:(HZBannerAd *)banner {
    [self logBannerCallback:_cmd];
}
- (void)bannerDidDismissModalView:(HZBannerAd *)banner {
    [self logBannerCallback:_cmd];
}
- (void)bannerWillLeaveApplication:(HZBannerAd *)banner {
    [self logBannerCallback:_cmd];
}

- (void)logBannerCallback:(SEL)selector {
    [self appendStringToDebugLog:[NSString stringWithFormat:@"Banner Callback: %@",NSStringFromSelector(selector)]];
}

@end
