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

@interface HZTestActivityNetworkViewController() <HZMediationAdapterDelegate>

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

@end

@implementation HZTestActivityNetworkViewController

#pragma mark - Initialization

- (instancetype) initWithNetwork:(HZBaseAdapter *)network rootVC:(UIViewController *)rootVC available:(BOOL)available initialized:(BOOL)initialized enabled:(BOOL)enabled {
    self = [super init];
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    self.network = network;
    self.rootVC = rootVC;
    self.available = available;
    self.initialized = initialized;
    self.enabled = enabled;
    
    // set this adapter's delegate to us so we can get callbacks
    self.network.delegate = self;
    
    // UnityAds starts with a view controller that is not us, need to set it since AppLovin apparently jacks it
    if ([[network name] isEqualToString:@"unityads"]) {
        [[HZUnityAds sharedInstance] setViewController:self];
    }
    
    return self;
}

#pragma mark - View lifecycle methods

- (void) viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:[self makeView]];
}

#pragma mark - UI action methods

- (void) back {
    // reset this network adapter's delegate
    self.network.delegate = [HeyzapMediation sharedInstance];
    
    // reset the UnityAds view controller
    if ([[[self.network class] name] isEqualToString:@"unityads"]) {
        [[HZUnityAds sharedInstance] setViewController:self.rootVC];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        // reset the root view controller
        [[[UIApplication sharedApplication] keyWindow] setRootViewController:self.rootVC];
    }];
}

- (void) refresh {
    // check available
    self.available = [[self.network class] isSDKAvailable] && ![[self.network class] isHeyzapAdapter];
    
    // hit the /info endpoint for enabled status and initialization credentials
    [[HZMediationAPIClient sharedClient] get:@"info" withParams:nil success:^(NSDictionary *json) {
        NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:json];
        NSArray *thisNetworkArray = [networks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *mediator, NSDictionary *bindings) {
            return [mediator[@"name"] isEqualToString:[[self.network class] name]];
        }]];
        
        // for whatever reason, sometimes /info doesn't always give disabled networks, in that case don't change anything
        if(thisNetworkArray.count == 1){
            NSDictionary *network = thisNetworkArray[0];

            // check enabled
            self.enabled = [network[@"enabled"] boolValue];

            // check original initialization succeeded
            if (self.network.credentials) {
                self.initialized = YES;
            } else {
                self.initialized = NO;
            }

            // if credentials have changed, pop an alert
            if (![self.network.credentials isEqualToDictionary:network[@"data"]]) {
                [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ credentials have changed", [[self.network class] humanizedName]]
                                            message:@"Restart the app to verify SDK initialization" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }

            NSLog(@"Available: %d", self.available);
            NSLog(@"Initialized: %d", self.initialized);
            NSLog(@"Enabled: %d", self.enabled);
            
            // update the checks and crosses
            [self setStatusForLabel:self.availableStatus withBool:self.available];
            [self setStatusForLabel:self.initializationStatus withBool:self.initialized];
            [self setStatusForLabel:self.enabledStatus withBool:self.enabled];
            
            // display or remove the ad controls
            if (self.available && self.initialized) {
                [self.adControls removeFromSuperview];
                self.adControls = [self makeAdControls];
                [self.view addSubview:self.adControls];
            } else {
                [self.adControls removeFromSuperview];
            }
        }
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error from /info: %@", error);
    }];
}

- (void) switchAdFormat:(UISegmentedControl *)adFormatControl {
    self.currentAdFormat = [[adFormatControl titleForSegmentAtIndex:adFormatControl.selectedSegmentIndex ] lowercaseString];
    self.currentAdType = [self adTypeWithString:self.currentAdFormat];
    NSLog(@"Current ad format: %@", self.currentAdFormat);
    if (![self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]]) {
        self.showButton.backgroundColor = [UIColor redColor];
    }
}

- (void) fetchAd {
    NSDictionary *additionalParams = @{ @"networks": [[self.network class] name] };
    [[HeyzapMediation sharedInstance] fetchForAdType:self.currentAdType tag:[HeyzapAds defaultTagName] additionalParams:additionalParams completion:^(BOOL result, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Fetch failed" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }

        [self changeShowButtonColor];
    }];
}

- (void) showAd {
    NSDictionary *additionalParams = @{ @"networks": [[self.network class] name] };
    [[HeyzapMediation sharedInstance] showAdForAdUnitType:self.currentAdType tag:[HeyzapAds defaultTagName] additionalParams:additionalParams completion:^(BOOL result, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Show failed" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }

        [self changeShowButtonColor];
    }];
}

#pragma mark - HZMediationAdapterDelegate methods

- (NSString *)countryCode{
    return @"us";
}

- (void)adapterWasClicked:(HZBaseAdapter *)adapter {
    
}

- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter {
    [self changeShowButtonColor];
}

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter {
    [self changeShowButtonColor];
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter {
    [self changeShowButtonColor];
}

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter {
    
}

- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter {
    
}

#pragma mark - View creation utility methods

- (UIView *) makeView {
    // top level view
    UIView *currentNetworkView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                                                                self.view.frame.size.width, self.view.frame.size.height - 45)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view;
    });
    
    // header
    UINavigationBar *header = ({
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame:CGRectMake(currentNetworkView.frame.origin.x, currentNetworkView.frame.origin.y,
                                                                                 currentNetworkView.frame.size.width, 44)];
        nav.barTintColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
        nav;
    });
    [[UINavigationBar appearance] setTitleTextAttributes:@{ UITextAttributeFont: [UIFont systemFontOfSize:18] }];
    
    // title, back, and reload button
    UINavigationItem *headerTitle = ({
        UINavigationItem *title = [[UINavigationItem alloc] initWithTitle:[[self.network class] humanizedName]];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
        title.leftBarButtonItem = back;
        title.rightBarButtonItem = refresh;
        title;
    });
    [header setItems:[NSArray arrayWithObject:headerTitle]];
    
    [currentNetworkView addSubview:header];
    
    // sdk available label
    UIView *availableView = [self makeStatusLabel:@"available" withStatus:self.available text:@"SDK Available" y:95];
    [currentNetworkView addSubview:availableView];
    
    // sdk initialization succeeded label
    UIView *initializationView = [self makeStatusLabel:@"initialization" withStatus:self.initialized text:@"SDK initialized with credentials" y:availableView.frame.origin.y + 15];
    [currentNetworkView addSubview:initializationView];

    // network is enabled label
    UIView *enabledView = [self makeStatusLabel:@"enabled" withStatus:self.enabled text:@"Network enabled on dashboard" y:initializationView.frame.origin.y + 15];
    [currentNetworkView addSubview:enabledView];
    
    // only show ad fetching/showing controls if the network was initialized correctly
    if(self.available && self.initialized){
        self.adControls = [self makeAdControls];
        [currentNetworkView addSubview:self.adControls];
    }
    
    return currentNetworkView;
}

- (UIView *) makeAdControls {
    UIView *adControls = ({
        UIView *controls = [[UIView alloc] initWithFrame:CGRectMake(10, 160, self.view.frame.size.width - 20, self.view.frame.size.height - 160)];
        controls.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        controls;
    });
    
    // setup currentAdFormat and currentAdTyp
    HZAdType supportedAdFormats = [self.network supportedAdFormats];
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
    self.currentAdFormat = [[formats objectAtIndex:0] lowercaseString];
    self.currentAdType = [self adTypeWithString:self.currentAdFormat];
    NSLog(@"Current ad format: %@", self.currentAdFormat);
    
    // segmented control for supported ad formats
    UISegmentedControl *adFormatControl = ({
        UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:formats];
        control.frame = CGRectMake(0, 0, adControls.frame.size.width, 40);
        control.selectedSegmentIndex = 0;
        control;
    });
    [adFormatControl addTarget:self action:@selector(switchAdFormat:) forControlEvents:UIControlEventValueChanged];
    [adControls addSubview:adFormatControl];
    
    // buttons for fetch and show
    UIButton *fetchButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(adFormatControl.frame.origin.x, adFormatControl.frame.origin.y + adFormatControl.frame.size.height + 10,
                                  adFormatControl.frame.size.width / 2.0 - 5, 40);
        button.backgroundColor = [UIColor darkGrayColor];
        button.layer.cornerRadius = 3.0;
        button;
    });
    [fetchButton setTitle:@"Fetch" forState:UIControlStateNormal];
    [fetchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [fetchButton addTarget:self action:@selector(fetchAd) forControlEvents:UIControlEventTouchUpInside];
    [adControls addSubview:fetchButton];
    
    self.showButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(fetchButton.frame.origin.x + fetchButton.frame.size.width + 10, fetchButton.frame.origin.y,
                                  adFormatControl.frame.size.width / 2.0 - 5, 40);
        button.backgroundColor = [UIColor redColor];
        button;
    });
    self.showButton.layer.cornerRadius = 3.0;
    [self.showButton setTitle:@"Show" forState:UIControlStateNormal];
    [self.showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.showButton addTarget:self action:@selector(showAd) forControlEvents:UIControlEventTouchUpInside];
    [adControls addSubview:self.showButton];
    
    return adControls;
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
    }
    
    return adType;
}

- (void) changeShowButtonColor {
    if ([self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]]) {
        self.showButton.backgroundColor = [UIColor greenColor];
    } else {
        self.showButton.backgroundColor = [UIColor redColor];
    }
}

@end
