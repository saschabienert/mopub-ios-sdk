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
#import "HZDispatch.h"
#import "HZUnityAds.h"

@interface HZTestActivityNetworkViewController()

@property (nonatomic) HZBaseAdapter *network;
@property (nonatomic) UIView *adControls;
@property (nonatomic) NSString *currentAdFormat;
@property (nonatomic) HZAdType currentAdType;
@property (nonatomic) UIButton *showButton;
@property (nonatomic) UILabel *availableStatus;
@property (nonatomic) UILabel *initializationStatus;
@property (nonatomic) UILabel *enabledStatus;

@end

@implementation HZTestActivityNetworkViewController

- (instancetype) initWithNetwork:(HZBaseAdapter *)network available:(NSSet *)available initialized:(NSSet *)initialized enabled:(NSSet *)enabled {
    self = [super init];
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    self.network = network;
    self.availableNetworks = available;
    self.initializedNetworks = initialized;
    self.enabledNetworks = enabled;
    
    // set this adapter's delegate to us so we can get callbacks
    self.network.delegate = self;
    
    // UnityAds starts with a view controller that is not us, need to set it since AppLovin apparently jacks it
    if ([[network name] isEqualToString:@"unityads"]) {
        [[HZUnityAds sharedInstance] setViewController:self];
    }
    
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:[self makeView]];
}

- (void) back {
    // reset this network adapter's delegate
    self.network.delegate = [HeyzapMediation sharedInstance];
    
    UIViewController *rootVC = ((HZTestActivityViewController *) self.presentingViewController).rootVC;
    
    // reset the UnityAds view controller
    if ([[[self.network class] name] isEqualToString:@"unityads"]) {
        [[HZUnityAds sharedInstance] setViewController:rootVC];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        // reset the root view controller
        [[[UIApplication sharedApplication] keyWindow] setRootViewController:rootVC];
    }];
}

- (void) refresh {
    [self checkNetworkInfo];
    
    BOOL available = [self.availableNetworks containsObject:self.network];
    [self setStatusForLabel:self.availableStatus withBool:available];
    
    BOOL initialized = [self.initializedNetworks containsObject:self.network];
    [self setStatusForLabel:self.initializationStatus withBool:initialized];
    
    BOOL enabled = [self.enabledNetworks containsObject:self.network];
    [self setStatusForLabel:self.enabledStatus withBool:enabled];
    
    if (available && initialized) {
        NSLog(@"adcontrols = %@",self.adControls);
        [self.adControls removeFromSuperview];
        self.adControls = [self makeAdControls];
        [self.view addSubview:self.adControls];
    } else {
        [self.adControls removeFromSuperview];
    }
}

- (void) switchAdFormat:(id)sender {
    UISegmentedControl *adFormatControl = (UISegmentedControl *) sender;
    self.currentAdFormat = [[adFormatControl titleForSegmentAtIndex:adFormatControl.selectedSegmentIndex ] lowercaseString];
    self.currentAdType = [self adTypeWithString:self.currentAdFormat];
    NSLog(@"Current ad format: %@", self.currentAdFormat);
    if (![self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]]) {
        self.showButton.backgroundColor = [UIColor redColor];
    }
}

- (void) fetchAd {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.network prefetchForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
        });
        
        __block BOOL fetchedWithinTimeout = NO;
        hzWaitUntil(^BOOL{
            fetchedWithinTimeout = [self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
            if([self.network lastErrorForAdType:self.currentAdType]){
                NSLog(@"Error fetching: %@", [self.network lastErrorForAdType:self.currentAdType]);
            }
            return [self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] || [self.network lastErrorForAdType:self.currentAdType] != nil;
        }, 10);
        
        if(fetchedWithinTimeout){
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"Fetched within timeout");
                self.showButton.backgroundColor = [UIColor greenColor];
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"Could not fetch within timeout");
                [[[UIAlertView alloc] initWithTitle:@"Fetch failed" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                if([self.network lastErrorForAdType:self.currentAdType]){
                    [self.network clearErrorForAdType:self.currentAdType];
                    [self.network prefetchForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
                }
            });
        }
    });
}

- (void) showAd {
    if([self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]]){
        [self.network showAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"No ad available" message:@"Try fetching one first" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (UIView *) makeView {
    // top level view
    UIView *currentNetworkView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                                                                self.view.frame.size.width, self.view.frame.size.height - 45)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view;
    });
    
    // header
    UIView *headerView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(currentNetworkView.frame.origin.x, currentNetworkView.frame.origin.y, self.view.frame.size.width, 60)];
        view.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
        UIView *border = [[UIView alloc] initWithFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y + view.frame.size.height - 1, view.frame.size.width, 1.0)];
        border.backgroundColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0];
        [view addSubview:border];
        view;
    });
    
    // network label
    UILabel *networkLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(headerView.frame.origin.x + 70, headerView.frame.origin.y,
                                                                   headerView.frame.size.width - 70, headerView.frame.size.height)];
        label.text = [[self.network class] humanizedName];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:20];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [headerView addSubview:label];
        label;
    });
    [headerView addSubview:networkLabel];
    
    // back button
    UIButton *closeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(headerView.frame.origin.x + 10, headerView.frame.origin.y + 10, 50, 40);
        button.backgroundColor = [UIColor lightGrayColor];
        button.layer.cornerRadius = 3.0;
        button;
    });
    [closeButton setTitle:@"Back" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:closeButton];
    
    // refresh button
    UIButton *refreshButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(headerView.frame.origin.x + headerView.frame.size.width - 90, headerView.frame.origin.y + 10, 80, 40);
        button.backgroundColor = [UIColor darkGrayColor];
        button.layer.cornerRadius = 3.0;
        button;
    });
    [refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    [refreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:refreshButton];
    
    [currentNetworkView addSubview:headerView];
    
    // sdk available label
    BOOL available = [self.availableNetworks containsObject:[[self.network class] sharedInstance]];
    
    UIView *availableView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(currentNetworkView.frame.origin.x + 10, headerView.frame.origin.y + headerView.frame.size.height + 5,
                                                                currentNetworkView.frame.size.width - 20, 30)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    UILabel *availableLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(availableView.frame.origin.x + 10, availableView.frame.origin.y - 65,
                                                                   availableView.frame.size.width - 20, availableView.frame.size.height)];
        label.text = @"SDK available";
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [availableView addSubview:availableLabel];
    
    self.availableStatus = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(availableView.frame.origin.x - 10, availableLabel.frame.origin.y, 20, availableLabel.frame.size.height)];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [self setStatusForLabel:self.availableStatus withBool:available];
    [availableView addSubview:self.availableStatus];
    
    [currentNetworkView addSubview:availableView];
    
    // sdk initialization succeeded label
    BOOL initialized = [self.initializedNetworks containsObject:[[self.network class] sharedInstance]];
    
    UIView *initializationView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(currentNetworkView.frame.origin.x + 10, availableView.frame.origin.y + 30,
                                                                currentNetworkView.frame.size.width - 20, 30)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    UILabel *initializationLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(initializationView.frame.origin.x + 10, initializationView.frame.origin.y - 95,
                                                                   initializationView.frame.size.width - 20, initializationView.frame.size.height)];
        label.text = @"SDK initialized with credentials";
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [initializationView addSubview:initializationLabel];
    
    self.initializationStatus = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(initializationView.frame.origin.x - 10, initializationLabel.frame.origin.y,
                                                                   20, initializationLabel.frame.size.height)];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [self setStatusForLabel:self.initializationStatus withBool:initialized];
    [initializationView addSubview:self.initializationStatus];
    
    [currentNetworkView addSubview:initializationView];
    
    // network is enabled label
    BOOL enabled = [self.enabledNetworks containsObject:[[self.network class] sharedInstance]];
    
    UIView *enabledView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(currentNetworkView.frame.origin.x + 10, initializationView.frame.origin.y + 30,
                                                                currentNetworkView.frame.size.width - 20, 30)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    
    UILabel *enabledLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(enabledView.frame.origin.x + 10, enabledView.frame.origin.y - 125,
                                                                   enabledView.frame.size.width - 20, enabledView.frame.size.height)];
        label.text = @"Network enabled on dashboard";
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [enabledView addSubview:enabledLabel];
    
    self.enabledStatus = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(enabledView.frame.origin.x - 10, enabledLabel.frame.origin.y,
                                                                   20, enabledLabel.frame.size.height)];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [self setStatusForLabel:self.enabledStatus withBool:enabled];
    [enabledView addSubview:self.enabledStatus];
    
    [currentNetworkView addSubview:enabledView];
    
    // only show ad fetching/showing controls if the network was initialized correctly
    if(available && initialized){
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

- (void) setStatusForLabel:(UILabel  *)label withBool:(BOOL)status {
    if (status) {
        label.text = @"☑︎";
        label.textColor = [UIColor greenColor];
    } else {
        label.text = @"☒";
        label.textColor = [UIColor redColor];
    }
}

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

- (NSString *)countryCode{
    return @"us";
}

- (void)adapterWasClicked:(HZBaseAdapter *)adapter {
    
}

- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter {
    if (![self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] ||
        [[self.network name] isEqualToString:@"admob"]) {
        self.showButton.backgroundColor = [UIColor redColor];
    } else {
        self.showButton.backgroundColor = [UIColor greenColor];
    }
}

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter {
    if (![self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] ||
        [[self.network name] isEqualToString:@"admob"]) {
        self.showButton.backgroundColor = [UIColor redColor];
    } else {
        self.showButton.backgroundColor = [UIColor greenColor];
    }
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter {
    if (![self.network hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] ||
        [[self.network name] isEqualToString:@"admob"]) {
        self.showButton.backgroundColor = [UIColor redColor];
    } else {
        self.showButton.backgroundColor = [UIColor greenColor];
    }
}

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter {
    
}

- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter {
    
}

@end
