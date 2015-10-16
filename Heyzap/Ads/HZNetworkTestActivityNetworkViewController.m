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

#import "HZNetworkTestActivityNetworkViewController.h"
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

@interface HZNetworkTestActivityNetworkViewController() <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, HZBannerAdDelegate, HZIncentivizedAdDelegate>

@property (nonatomic) HZBaseAdapter *network;
@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) BOOL available;
@property (nonatomic) BOOL hasCredentials;
@property (nonatomic) BOOL enabled;
@property (nonatomic) UIView *adControls;
@property (nonatomic) NSString *currentAdFormat;
@property (nonatomic) HZAdType currentAdType;
@property (nonatomic) UIButton *showButton;
@property (nonatomic) UILabel *availableStatus;
@property (nonatomic) UILabel *hasCredentialsStatus;
@property (nonatomic) UILabel *enabledStatus;
@property (nonatomic) UITextView *debugLog;

@property (nonatomic) UITextField *adTagField;

@property (nonatomic) UIButton *showBannerButton;
@property (nonatomic) UIButton *hideBannerButton;

@property (nonatomic) UIPickerView *bannerPositionPickerView;
@property (nonatomic) UIPickerView *bannerSizePickerView;

@property (nonatomic) UITextField *bannerPositionTextField;
@property (nonatomic) UITextField *bannerSizeTextField;

@property (nonatomic) HZBannerPosition chosenBannerPosition;
@property (nonatomic) NSValue *chosenBannerSize;

@property (nonatomic) NSArray<UIControl *> *nonBannerControls;
@property (nonatomic) NSArray<UIControl *> *bannerControls;

@property (nonatomic) HZBannerAd *bannerWrapper;

@property (nonatomic, strong) UIScrollView *scrollView;

NSValue *hzBannerPositionValue(HZBannerPosition position);
HZBannerPosition hzBannerPositionFromNSValue(NSValue *value);
NSString *hzBannerPositionName(HZBannerPosition position);

@property (nonatomic, weak) id<HZAdsDelegate> previousInterstitialDelegate;
@property (nonatomic, weak) id<HZAdsDelegate> previousVideoDelegate;
@property (nonatomic, weak) id<HZAdsDelegate> previousIncentivizedDelegate;

@end

@implementation HZNetworkTestActivityNetworkViewController

#pragma mark - Initialization

- (instancetype) initWithNetwork:(HZBaseAdapter *)network rootVC:(UIViewController *)rootVC available:(BOOL)available hasCredentials:(BOOL)hasCredentials enabled:(BOOL)enabled {
    self = [super init];
    
    if (self) {
        self.network = network;
        self.rootVC = rootVC;
        self.available = available;
        self.hasCredentials = hasCredentials;
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
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds]; // Set contentSize later dynamically
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [self makeView];
    [self updateScrollViewContentSize];
    [self.view addSubview:self.scrollView];
    
    [self showOrHideBannerControls];
    
    if ([self.network testActivityInstructions]) {
        [self appendStringToDebugLog:[self.network testActivityInstructions]];
    }
    
    // Dismisses first responder (keyboard)
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]];
}

- (void)viewTapped:(UITapGestureRecognizer *)sender{
    [sender.view endEditing:YES];
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

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return YES;
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
            self.hasCredentials = [self.network hasNecessaryCredentials];

            // if credentials have changed, pop an alert
            if (![self.network.credentials isEqualToDictionary:network[@"data"]] && self.enabled) {
                [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ credentials have changed", [[self.network class] humanizedName]]
                                            message:@"Restart the app to verify SDK initialization" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }

            HZDLog(@"Available: %d", self.available);
            HZDLog(@"Has credentials: %d", self.hasCredentials);
            HZDLog(@"Enabled: %d", self.enabled);
            
            // update the checks and crosses
            [self setStatusForLabel:self.availableStatus withBool:self.available];
            [self setStatusForLabel:self.hasCredentialsStatus withBool:self.hasCredentials];
            [self setStatusForLabel:self.enabledStatus withBool:self.enabled];
            
            // display or remove the ad controls
            if (self.available && self.hasCredentials) {
                
                [self hideBanner];
                
                UIView *const previousSuperview = self.adControls.superview;
                
                [self.adControls removeFromSuperview];
                self.adControls = [self makeAdControls];
                [previousSuperview addSubview:self.adControls];
            } else {
                [self.adControls removeFromSuperview];
            }
            [self showOrHideBannerControls];
            [self updateScrollViewContentSize];
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
        [self checkAvailabilityAndChangeColorOfShowButton];
        [self hideBanner];
    }
}

- (void)showOrHideBannerControls {
    [self.bannerControls setValue:@(self.currentAdType != HZAdTypeBanner) forKey:@"hidden"];
    [self.nonBannerControls setValue:@(self.currentAdType == HZAdTypeBanner) forKey:@"hidden"];
    
    if ([[self bannerSizes] count] == 0) {
        self.bannerSizeTextField.hidden = YES;
    }

    [self.view endEditing:YES]; // Dismisses picker views and keyboard
}

- (void) isAvailableButtonPressed {
    [self.view endEditing:YES];// Dismisses picker views and keyboard
    
    // use HZShowOptions to format the tag for the log output
    HZShowOptions *options = [HZShowOptions new];
    options.tag = [self.adTagField text];
    [self appendStringToDebugLog:[NSString stringWithFormat:@"%@ ad %@ available for tag '%@'.", self.currentAdFormat,([self checkAvailabilityAndChangeColorOfShowButton] ? @"is" : @"is not"), options.tag]];
}

- (void) fetchAd {
    [self.view endEditing:YES];// Dismisses picker views and keyboard
    
    // check if at least one of the supported creativeTypes for this adType has credentials, warn if not
    NSSet *creativeTypesToCheck = hzCreativeTypesPossibleForAdType(self.currentAdType);
    BOOL foundCredentials = NO;
    
    for(NSNumber *creativeTypeNum in creativeTypesToCheck) {
        if ([self.network hasCredentialsForCreativeType:hzCreativeTypeFromNSNumber(creativeTypeNum)]) {
            foundCredentials = YES;
        }
    }
    if (!foundCredentials) {
        [self appendStringToDebugLog:@"This network doesn't have credentials set for this ad type. Make sure you've added credentials on the Heyzap dashboard."];
        return;
    }
    
    HZFetchOptions *fetchOptions = [HZFetchOptions new];
    fetchOptions.requestingAdType = self.currentAdType;
    fetchOptions.tag = [self.adTagField text];
    fetchOptions.additionalParameters = @{ @"network": [[self.network class] name] };
    fetchOptions.completion = ^(BOOL result, NSError *error) {
        if (error) {
            [self appendStringToDebugLog:@"Fetch failed"];
        } else {
            [self appendStringToDebugLog:@"Fetch succeeded"];
        }
        
        [self checkAvailabilityAndChangeColorOfShowButton];
    };
    
    [self appendStringToDebugLog:[NSString stringWithFormat:@"Fetching ad with tag: '%@' (may take up to 10 seconds)", fetchOptions.tag]];
    [[HeyzapMediation sharedInstance] fetchWithOptions:fetchOptions];
}

- (void) showAd {
    [self.view endEditing:YES];// Dismisses picker views and keyboard
    
    NSDictionary *additionalParams = @{ @"network": [[self.network class] name] };

    HZShowOptions *options = [HZShowOptions new];
    options.tag = [self.adTagField text];
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

        [self checkAvailabilityAndChangeColorOfShowButton];
    };
    
    [self appendStringToDebugLog:[NSString stringWithFormat:@"Showing ad with tag: '%@'", options.tag]];
    [[HeyzapMediation sharedInstance] showForAdType:self.currentAdType additionalParams:additionalParams options:options];
}

#pragma mark - HZAdDelegate methods

- (void)didShowAdWithTag: (NSString *) tag {
    [self logCallback:_cmd];
}

- (void)didFailToShowAdWithTag: (NSString *) tag andError: (NSError *)error {
    [self checkAvailabilityAndChangeColorOfShowButton];
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
    [self checkAvailabilityAndChangeColorOfShowButton];
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

- (void) makeView {
    // sdk available label
    UIView *availableView = [self makeStatusLabel:@"available" withStatus:self.available text:@"SDK Available" y:15];
    [self.scrollView addSubview:availableView];
    
    // sdk initialization succeeded label
    UIView *hasCredentialsView = [self makeStatusLabel:@"credentials" withStatus:self.hasCredentials text:@"SDK has necessary credentials" y:(CGRectGetMaxY(availableView.frame) + 5)];
    [self.scrollView addSubview:hasCredentialsView];

    // network is enabled label
    UIView *enabledView = [self makeStatusLabel:@"enabled" withStatus:self.enabled text:@"Network enabled on dashboard" y:(CGRectGetMaxY(hasCredentialsView.frame) + 5)];
    [self.scrollView addSubview:enabledView];
    
    // only show ad fetching/showing controls and debug log if the network was initialized correctly
    if(self.available && self.hasCredentials){
        self.adControls = [self makeAdControls];
        [self.scrollView addSubview:self.adControls];

        // debug log
        self.debugLog = ({
            UITextView *text = [[UITextView alloc] initWithFrame:CGRectMake(self.adControls.frame.origin.x,
                                                                            CGRectGetMaxY(self.adControls.frame),
                                                                            CGRectGetWidth(self.adControls.frame),
                                                                            MAX(CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.adControls.frame) - 60, 200/*min height*/))];
            text.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            text.editable = false;
            text.font = [UIFont fontWithName: @"Courier" size: 12.0];
            text.text = @"Debug log:";
            text;
        });
        
        UIView *debugLogShadow = ({
            UIView *view = [[UIView alloc] initWithFrame:self.debugLog.frame];
            view.layer.shadowColor = [UIColor grayColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(0, 3);
            view.layer.shadowOpacity = 1;
            view.layer.shadowRadius = 2;
            view.layer.masksToBounds = NO;
            view.autoresizingMask = self.debugLog.autoresizingMask;
            view.backgroundColor = [UIColor whiteColor];
            view;
        });
        
        [self.scrollView addSubview:debugLogShadow];
        [self.scrollView addSubview:self.debugLog];
    }
}

- (UIView *) makeAdControls {
    UIView *adControls = ({
        UIView *controls = [[UIView alloc] initWithFrame:CGRectMake(10, 100, self.view.frame.size.width - 20, 200)];
        controls.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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
        control.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        control.selectedSegmentIndex = 0;
        control;
    });
    [adFormatControl addTarget:self action:@selector(switchAdFormat:) forControlEvents:UIControlEventValueChanged];
    [adControls addSubview:adFormatControl];
    
    
    const CGFloat buttonWidth = adFormatControl.frame.size.width / 2.0 - 5;
    self.adTagField = [[UITextField alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(adFormatControl.frame) + 10, buttonWidth, 40)];
    self.adTagField.delegate = self;
    self.adTagField.borderStyle = UITextBorderStyleRoundedRect;
    self.adTagField.keyboardType = UIKeyboardTypeDefault;
    self.adTagField.placeholder = @"Ad Tag";
    self.adTagField.textAlignment = NSTextAlignmentLeft;
    self.adTagField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    self.adTagField.accessibilityLabel = @"ad tag";
    [self.adTagField addTarget:self
                        action:@selector(adTagEditingChanged:)
              forControlEvents:UIControlEventEditingChanged];
    [adControls addSubview:self.adTagField];
    
    UIButton *availableButton = ({
        UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor darkGrayColor]];
        button.frame = CGRectMake(CGRectGetMaxX(self.adTagField.frame) + 10, CGRectGetMinY(self.adTagField.frame), CGRectGetWidth(self.adTagField.frame), CGRectGetHeight(self.adTagField.frame));
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        [button setTitle:@"Ad Available?" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(isAvailableButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [adControls addSubview:availableButton];
    
    
    const CGRect leftButtonFrame = CGRectMake(self.adTagField.frame.origin.x, self.adTagField.frame.origin.y + self.adTagField.frame.size.height + 10, buttonWidth, 40);
    const CGRect rightButtonFrame = CGRectMake(CGRectGetMaxX(leftButtonFrame) + 10, leftButtonFrame.origin.y, buttonWidth, 40);
    
    // buttons for fetch and show
    UIButton *fetchButton = ({
        UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor darkGrayColor]];
        button.frame = leftButtonFrame;
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [button setTitle:@"Fetch" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(fetchAd) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [adControls addSubview:fetchButton];
    
    self.showButton = ({
        UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor redColor]];
        button.frame = rightButtonFrame;
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        [button setTitle:@"Show" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showAd) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [adControls addSubview:self.showButton];
    
    self.nonBannerControls = @[fetchButton, self.showButton, availableButton];
    
    if ([self showBanners]) {
        
        self.hideBannerButton = ({
            UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor darkGrayColor]];
            button.enabled = NO;
            button.frame = leftButtonFrame;
            button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [button setTitle:@"Hide" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            [button addTarget:self action:@selector(hideBanner:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [adControls addSubview:self.hideBannerButton];
        
        self.showBannerButton = ({
            UIButton *button = [[self class] buttonWithBackgroundColor:[UIColor darkGrayColor]];
            button.frame = rightButtonFrame;
            button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
            [button setTitle:@"Show" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            [button addTarget:self action:@selector(showBanner:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [adControls addSubview:self.showBannerButton];
        
        
        const CGFloat positionY = CGRectGetMaxY(fetchButton.frame) + 10;
        
        self.bannerPositionTextField = ({
            HZNoCaretTextField *textField = [[HZNoCaretTextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.hideBannerButton.frame), positionY, buttonWidth, 40)];
            textField.delegate = self;
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
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
            textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
            
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
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(10, y, 300, 20)];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    UILabel *statusLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                   0,
                                                                   20,
                                                                   CGRectGetHeight(wrapperView.frame))];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label;
    });
    [self setStatusForLabel:statusLabel withBool:status];
    [wrapperView addSubview:statusLabel];
    
    UILabel *textLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(statusLabel.frame),
                                                                   0,
                                                                   CGRectGetWidth(wrapperView.frame) - CGRectGetWidth(statusLabel.frame),
                                                                   CGRectGetHeight(wrapperView.frame))];
        label.text = text;
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label;
    });
    [wrapperView addSubview:textLabel];

    if ([type isEqualToString:@"available"]) {
        self.availableStatus = statusLabel;
    } else if ([type isEqualToString:@"credentials"]) {
        self.hasCredentialsStatus = statusLabel;
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

- (BOOL) checkAvailabilityAndChangeColorOfShowButton {
    const BOOL available = [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:self.currentAdType tag:[self.adTagField text] network:self.network];
    if (available) {
        self.showButton.backgroundColor = [UIColor greenColor];
    } else {
        self.showButton.backgroundColor = [UIColor redColor];
    }
    
    return available;
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

#pragma mark - UITextField delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)adTagEditingChanged:(UITextField *)sender {
    [self checkAvailabilityAndChangeColorOfShowButton];
}

- (void)updateScrollViewContentSize
{
    // This approach avoids constant manual adjustment
    CGRect subviewContainingRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        subviewContainingRect = CGRectUnion(subviewContainingRect, view.frame);
    }
    self.scrollView.contentSize = (CGSize) { CGRectGetWidth(self.view.frame), subviewContainingRect.size.height };
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateScrollViewContentSize];
}
@end