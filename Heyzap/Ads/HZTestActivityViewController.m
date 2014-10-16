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

#import "HeyzapAds.h"
#import "HeyzapMediation.h"
#import "HZBaseAdapter.h"
#import "HZAdFetchRequest.h"
#import "HZMediationConstants.h"
#import "HZMediationAPIClient.h"
#import "HZMediationSession.h"
#import "HZMediationSessionKey.h"
#import "HZTestActivityViewController.h"
#import "HZDispatch.h"
#import "HZUnityAds.h"
#import "HZDictionaryUtils.h"

@interface HZTestActivityViewController()

@property (nonatomic) NSSet *availableNetworks;
@property (nonatomic) NSSet *initializedNetworks;
@property (nonatomic) NSSet *enabledNetworks;
@property (nonatomic) BOOL statusBarHidden;
@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) NSArray *allNetworks;
@property (nonatomic) UIView *chooseNetworkView;
@property (nonatomic) UIView *currentNetworkView;
@property (nonatomic) UIView *adControls;
@property (nonatomic) HZBaseAdapter *currentNetworkAdapter;
@property (nonatomic) NSString *currentAdFormat;
@property (nonatomic) HZAdType currentAdType;
@property (nonatomic) UIButton *showButton;
@property (nonatomic) UILabel *availableStatus;
@property (nonatomic) UILabel *initializationStatus;
@property (nonatomic) UILabel *enabledStatus;

@end

@implementation HZTestActivityViewController

+ (void) show {
    NSLog(@"Showing test activity view controller");

    HZTestActivityViewController *vc = [[self alloc] init];
    
    // save whether the status bar is hidden
    vc.statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    // check for a root view controller
    vc.rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (!vc.rootVC) {
        NSLog(@"Heyzap requires a root view controller to display the test activity. Set the `rootViewController` property of [UIApplication sharedApplication].keyWindow to fix this error. If you have any trouble doing this, contact support@heyzap.com");
        return;
    }

    // get the list of all networks
    NSSet *nonHeyzapNetworks = [[HZBaseAdapter allAdapterClasses] filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Class adapterClass, NSDictionary *bindings) {
        return ![adapterClass isHeyzapAdapter];
    }]];
    vc.allNetworks = [[nonHeyzapNetworks allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *name1 = [(HZBaseAdapter *) obj1 name];
        NSString *name2 = [(HZBaseAdapter *) obj2 name];
        return [name1 compare:name2];
    }];
    NSLog(@"All networks: %@", vc.allNetworks);
    
    // get the networks' enabled status and credentials to build sets of enabled and initialized networks
    [vc checkNetworkInfo];

    // take over the screen
    [[[UIApplication sharedApplication] keyWindow] setRootViewController:vc];
    [[UIApplication sharedApplication] setStatusBarHidden: YES];
}

- (void) hide {
    NSLog(@"Hiding test activity view controller");

    // Don't forget to reset all of the adapter's delegates
    for (HZBaseAdapter *adapter in self.initializedNetworks) {
        adapter.delegate = [HeyzapMediation sharedInstance];
    }
    
    // Don't forget to reset the UnityAds view controller
    [[HZUnityAds sharedInstance] setViewController:self.rootVC];
    
    [[[UIApplication sharedApplication] keyWindow] setRootViewController:self.rootVC];
    [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarHidden];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // page
    self.view.backgroundColor = [UIColor whiteColor];
 
    // choose a network view
    self.chooseNetworkView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                                                                      self.view.frame.size.width, self.view.frame.size.height)];
    
    // header
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, 60)];
    headerView.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    CALayer *border = [CALayer layer];
    border.frame = CGRectMake(headerView.frame.origin.x, headerView.frame.origin.y + headerView.frame.size.height - 1, headerView.frame.size.width, 1.0);
    border.backgroundColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0].CGColor;
    [headerView.layer addSublayer:border];
    
    // back button
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    backButton.frame = CGRectMake(10, 10, 50, 40);
    backButton.backgroundColor = [UIColor lightGrayColor];
    backButton.layer.cornerRadius = 3.0;
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:backButton];
    
    // title
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, headerView.frame.size.width - 60, 60)];
    headerLabel.text = @"Heyzap Mediation Testing";
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont systemFontOfSize:20];
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerView addSubview:headerLabel];
    [self.chooseNetworkView addSubview:headerView];
    
    // choose network label
    UILabel *chooseLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.chooseNetworkView.frame.origin.x + 10, self.chooseNetworkView.frame.origin.y + headerView.frame.size.height,
                                                                     self.chooseNetworkView.frame.size.width - 10, 32)];
    chooseLabel.text = @"Choose a network:";
    chooseLabel.backgroundColor = [UIColor clearColor];
    chooseLabel.font = [UIFont systemFontOfSize:12];
    chooseLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.chooseNetworkView addSubview:chooseLabel];
    
    // networks table view
    UITableView *networksTableView = [[UITableView alloc]
                                      initWithFrame:CGRectMake(self.chooseNetworkView.frame.origin.x,
                                                               self.chooseNetworkView.frame.origin.y + headerView.frame.size.height + chooseLabel.frame.size.height,
                                                               self.chooseNetworkView.frame.size.width, self.chooseNetworkView.frame.size.height - chooseLabel.frame.size.height)
                                      style:UITableViewStylePlain];
    networksTableView.backgroundColor = [UIColor clearColor];
    networksTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    networksTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    networksTableView.delegate = self;
    networksTableView.dataSource = self;
    [networksTableView reloadData];
    [self.chooseNetworkView addSubview:networksTableView];
    
    [self.view addSubview:self.chooseNetworkView];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allNetworks count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"];
    }
    NSString *name = [[self.allNetworks objectAtIndex:indexPath.row] name];
    cell.textLabel.text = [self humanizedNetworkName:name];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    HZBaseAdapter *network = [self.allNetworks objectAtIndex:indexPath.row];
    self.currentNetworkAdapter = [[network class] sharedInstance];
    NSLog(@"Current network adapter: %@", self.currentNetworkAdapter);
    
    [self makeViewForNetwork:network];
    [UIView transitionFromView:self.chooseNetworkView toView:self.currentNetworkView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight completion:nil];
}

- (void) makeViewForNetwork:(HZBaseAdapter *)network {
    // UnityAds starts with a view controller that is not us, need to set it since AppLovin apparently jacks it
    [[HZUnityAds sharedInstance] setViewController:self];
    
    // top level view
    self.currentNetworkView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                                                                   self.view.frame.size.width, self.view.frame.size.height - 45)];
    self.currentNetworkView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    // header
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(self.currentNetworkView.frame.origin.x, self.currentNetworkView.frame.origin.y, self.view.frame.size.width, 60)];
    headerView.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    CALayer *border = [CALayer layer];
    border.frame = CGRectMake(headerView.frame.origin.x, headerView.frame.origin.y + headerView.frame.size.height - 1, headerView.frame.size.width, 1.0);
    border.backgroundColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0].CGColor;
    [headerView.layer addSublayer:border];
    
    // network label
    UILabel *networkLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerView.frame.origin.x + 70, headerView.frame.origin.y,
                                                                      headerView.frame.size.width - 70, headerView.frame.size.height)];
    networkLabel.text = [self humanizedNetworkName:[network name]];
    networkLabel.textAlignment = NSTextAlignmentLeft;
    networkLabel.backgroundColor = [UIColor clearColor];
    networkLabel.font = [UIFont systemFontOfSize:20];
    networkLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerView addSubview:networkLabel];
    
    // back button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    closeButton.frame = CGRectMake(headerView.frame.origin.x + 10, headerView.frame.origin.y + 10, 50, 40);
    closeButton.backgroundColor = [UIColor lightGrayColor];
    closeButton.layer.cornerRadius = 3.0;
    [closeButton setTitle:@"Back" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [headerView insertSubview:closeButton aboveSubview:networkLabel];
    [self.currentNetworkView addSubview:headerView];
    
    // refresh button
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    refreshButton.frame = CGRectMake(headerView.frame.origin.x + headerView.frame.size.width - 90, headerView.frame.origin.y + 10, 80, 40);
    refreshButton.backgroundColor = [UIColor darkGrayColor];
    refreshButton.layer.cornerRadius = 3.0;
    [refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    [refreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
    [self.currentNetworkView addSubview:refreshButton];

    // sdk available label
    BOOL available = [self.availableNetworks containsObject:[[network class] sharedInstance]];
    UIView *availableView = [[UIView alloc] initWithFrame:CGRectMake(self.currentNetworkView.frame.origin.x + 10, headerView.frame.origin.y + headerView.frame.size.height + 5,
                                                                     self.currentNetworkView.frame.size.width - 20, 30)];
    availableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    availableView.backgroundColor = [UIColor clearColor];
    UILabel *availableLabel = [[UILabel alloc] initWithFrame:CGRectMake(availableView.frame.origin.x + 10, availableView.frame.origin.y - 65,
                                                                        availableView.frame.size.width - 20, availableView.frame.size.height)];
    availableLabel.text = @"SDK available";
    availableLabel.textAlignment = NSTextAlignmentLeft;
    availableLabel.backgroundColor = [UIColor clearColor];
    availableLabel.font = [UIFont systemFontOfSize:16];
    availableLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [availableView addSubview:availableLabel];
    self.availableStatus = [[UILabel alloc] initWithFrame:CGRectMake(availableView.frame.origin.x - 10, availableLabel.frame.origin.y, 20, availableLabel.frame.size.height)];
    if(available){
        self.availableStatus.text = @"☑︎";
        self.availableStatus.textColor = [UIColor greenColor];
    } else {
        self.availableStatus.text = @"☒";
        self.availableStatus.textColor = [UIColor redColor];
    }
    self.availableStatus.textAlignment = NSTextAlignmentLeft;
    self.availableStatus.backgroundColor = [UIColor clearColor];
    self.availableStatus.font = [UIFont systemFontOfSize:16];
    self.availableStatus.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [availableView addSubview:self.availableStatus];
    [self.currentNetworkView addSubview:availableView];
    
    // sdk initialization succeeded label
    BOOL initialized = [self.initializedNetworks containsObject:[[network class] sharedInstance]];
    UIView *initializationView = [[UIView alloc] initWithFrame:CGRectMake(self.currentNetworkView.frame.origin.x + 10, availableView.frame.origin.y + 30,
                                                                          self.currentNetworkView.frame.size.width - 20, 30)];
    initializationView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    initializationView.backgroundColor = [UIColor clearColor];
    UILabel *initializationLabel = [[UILabel alloc] initWithFrame:CGRectMake(initializationView.frame.origin.x + 10, initializationView.frame.origin.y - 95,
                                                                             initializationView.frame.size.width - 20, initializationView.frame.size.height)];
    initializationLabel.text = @"SDK initialized with credentials";
    initializationLabel.textAlignment = NSTextAlignmentLeft;
    initializationLabel.backgroundColor = [UIColor clearColor];
    initializationLabel.font = [UIFont systemFontOfSize:16];
    initializationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [initializationView addSubview:initializationLabel];
    self.initializationStatus = [[UILabel alloc] initWithFrame:CGRectMake(initializationView.frame.origin.x - 10, initializationLabel.frame.origin.y,
                                                                              20, initializationLabel.frame.size.height)];
    if(initialized){
        self.initializationStatus.text = @"☑︎";
        self.initializationStatus.textColor = [UIColor greenColor];
    } else {
        self.initializationStatus.text = @"☒";
        self.initializationStatus.textColor = [UIColor redColor];
    }
    self.initializationStatus.textAlignment = NSTextAlignmentLeft;
    self.initializationStatus.backgroundColor = [UIColor clearColor];
    self.initializationStatus.font = [UIFont systemFontOfSize:16];
    self.initializationStatus.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [initializationView addSubview:self.initializationStatus];
    [self.currentNetworkView addSubview:initializationView];
    
    // network is enabled label
    BOOL enabled = [self.enabledNetworks containsObject:[[network class] sharedInstance]];
    UIView *enabledView = [[UIView alloc] initWithFrame:CGRectMake(self.currentNetworkView.frame.origin.x + 10, initializationView.frame.origin.y + 30,
                                                                   self.currentNetworkView.frame.size.width - 20, 30)];
    enabledView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    enabledView.backgroundColor = [UIColor clearColor];
    UILabel *enabledLabel = [[UILabel alloc] initWithFrame:CGRectMake(enabledView.frame.origin.x + 10, enabledView.frame.origin.y - 125,
                                                                      enabledView.frame.size.width - 20, enabledView.frame.size.height)];
    enabledLabel.text = @"Network enabled on dashboard";
    enabledLabel.textAlignment = NSTextAlignmentLeft;
    enabledLabel.backgroundColor = [UIColor clearColor];
    enabledLabel.font = [UIFont systemFontOfSize:16];
    enabledLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [enabledView addSubview:enabledLabel];
    self.enabledStatus = [[UILabel alloc] initWithFrame:CGRectMake(enabledView.frame.origin.x - 10, enabledLabel.frame.origin.y,
                                                                       20, enabledLabel.frame.size.height)];
    if(enabled){
        self.enabledStatus.text = @"☑︎";
        self.enabledStatus.textColor = [UIColor greenColor];
    } else {
        self.enabledStatus.text = @"☒";
        self.enabledStatus.textColor = [UIColor redColor];
    }
    self.enabledStatus.textAlignment = NSTextAlignmentLeft;
    self.enabledStatus.backgroundColor = [UIColor clearColor];
    self.enabledStatus.font = [UIFont systemFontOfSize:16];
    self.enabledStatus.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [enabledView addSubview:self.enabledStatus];
    [self.currentNetworkView addSubview:enabledView];

    // only show ad fetching/showing controls if the network was initialized correctly
    if(available && initialized){
        [self makeAdControls];
    }
}

- (void) makeAdControls {
    [self.adControls removeFromSuperview];
    self.adControls = [[UIView alloc] initWithFrame:CGRectMake(10, 160, self.view.frame.size.width - 20, self.view.frame.size.height - 160)];
    self.adControls.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    // segmented control for supported ad formats
    HZAdType supportedAdFormats = [self.currentNetworkAdapter supportedAdFormats];
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
    
    UISegmentedControl *adFormatControl = [[UISegmentedControl alloc] initWithItems:formats];
    adFormatControl.frame = CGRectMake(0, 0, self.adControls.frame.size.width, 40);
    adFormatControl.selectedSegmentIndex = 0;
    [adFormatControl addTarget:self action:@selector(switchAdFormat:) forControlEvents:UIControlEventValueChanged];
    [self.adControls addSubview:adFormatControl];
    
    // buttons for fetch and show
    UIButton *fetchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    fetchButton.frame = CGRectMake(adFormatControl.frame.origin.x, adFormatControl.frame.origin.y + adFormatControl.frame.size.height + 10,
                                   adFormatControl.frame.size.width / 2.0 - 5, 40);
    fetchButton.backgroundColor = [UIColor darkGrayColor];
    fetchButton.layer.cornerRadius = 3.0;
    [fetchButton setTitle:@"Fetch" forState:UIControlStateNormal];
    [fetchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [fetchButton addTarget:self action:@selector(fetchAd) forControlEvents:UIControlEventTouchUpInside];
    [self.adControls addSubview:fetchButton];
    
    self.showButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.showButton.frame = CGRectMake(fetchButton.frame.origin.x + fetchButton.frame.size.width + 10, fetchButton.frame.origin.y,
                                       adFormatControl.frame.size.width / 2.0 - 5, 40);
    // i know this is gross, but for some reason hasAdForType:tag: was returning true for all networks here
    if ([[self.currentNetworkAdapter name] isEqualToString:@"unityads"]) {
        self.showButton.backgroundColor = [UIColor greenColor];
    } else {
        self.showButton.backgroundColor = [UIColor redColor];
    }
    self.showButton.layer.cornerRadius = 3.0;
    [self.showButton setTitle:@"Show" forState:UIControlStateNormal];
    [self.showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.showButton addTarget:self action:@selector(showAd) forControlEvents:UIControlEventTouchUpInside];
    [self.adControls addSubview:self.showButton];
    
    [self.currentNetworkView addSubview:self.adControls];
}

- (void) back {
    self.currentNetworkAdapter = nil;
    self.currentAdFormat = nil;
    self.currentAdType = 0;
    self.showButton = nil;
    self.availableStatus = nil;
    self.initializationStatus = nil;
    self.enabledStatus = nil;
    self.adControls = nil;
    [UIView transitionFromView:self.currentNetworkView toView:self.chooseNetworkView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft completion:nil];
    self.currentNetworkView = nil;
}

- (void) switchAdFormat:(id)sender {
    UISegmentedControl *adFormatControl = (UISegmentedControl *) sender;
    self.currentAdFormat = [[adFormatControl titleForSegmentAtIndex:adFormatControl.selectedSegmentIndex ] lowercaseString];
    self.currentAdType = [self adTypeWithString:self.currentAdFormat];
    NSLog(@"Current ad format: %@", self.currentAdFormat);
    if (![self.currentNetworkAdapter hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]]) {
        self.showButton.backgroundColor = [UIColor redColor];
    }
}

- (void) checkNetworkInfo {
    // check available
    NSMutableSet *availableNetworks = [NSMutableSet set];
    for( HZBaseAdapter *adapter in [HZBaseAdapter allAdapterClasses]){
        if(![[adapter class] isHeyzapAdapter] && [[adapter class] isSDKAvailable]){
            [availableNetworks addObject:[[adapter class] sharedInstance]];
        }
    }
    self.availableNetworks = availableNetworks;

    [[HZMediationAPIClient sharedClient] get:@"info" withParams:nil success:^(NSDictionary *json) {
        NSMutableSet *enabledNetworks = [NSMutableSet set];
        NSMutableSet *initializedNetworks = [NSMutableSet set];
        NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:json];
        for (NSDictionary *mediator in networks) {
            NSString *mediatorName = mediator[@"name"];
            Class mediatorClass = [HZBaseAdapter adapterClassForName:mediatorName];
            
            // check enabled
            if([mediator[@"enabled"] boolValue]){
                [enabledNetworks addObject:[mediatorClass sharedInstance]];
            }
            
            // check initialization
            NSDictionary *mediatorInfo = mediator[@"data"];
            if (mediatorClass && mediatorInfo && [mediatorClass isSDKAvailable]) {
                NSError *credentialError = [mediatorClass enableWithCredentials:mediatorInfo];
                if (!credentialError) {
                    HZBaseAdapter *adapter = [mediatorClass sharedInstance];
                    adapter.delegate = self;
                    [initializedNetworks addObject:adapter];
                }
            }
        }
        self.enabledNetworks = enabledNetworks;
        self.initializedNetworks = initializedNetworks;
        NSLog(@"Networks available: %@", self.availableNetworks);
        NSLog(@"Networks initialized: %@", self.initializedNetworks);
        NSLog(@"Networks enabled: %@", self.enabledNetworks);
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error from /start: %@", error);
    }];
}

- (void) fetchAd {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.currentNetworkAdapter prefetchForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
        });

        __block BOOL fetchedWithinTimeout = NO;
        hzWaitUntil(^BOOL{
            fetchedWithinTimeout = [self.currentNetworkAdapter hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
            if([self.currentNetworkAdapter lastErrorForAdType:self.currentAdType]){
                NSLog(@"Error fetching: %@", [self.currentNetworkAdapter lastErrorForAdType:self.currentAdType]);
            }
            return [self.currentNetworkAdapter hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] || [self.currentNetworkAdapter lastErrorForAdType:self.currentAdType] != nil;
        }, 10);
        
        if(fetchedWithinTimeout){
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"Fetched within timeout");
                self.showButton.backgroundColor = [UIColor greenColor];
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"Could not fetch within timeout");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fetch failed" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                if([self.currentNetworkAdapter lastErrorForAdType:self.currentAdType]){
                    [self.currentNetworkAdapter clearErrorForAdType:self.currentAdType];
                    [self.currentNetworkAdapter prefetchForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
                }
            });
        }
    });
}

- (void) showAd {
    if([self.currentNetworkAdapter hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]]){
        [self.currentNetworkAdapter showAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No ad available" message:@"Try fetching one first" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void) refresh {
    [self checkNetworkInfo];

    BOOL available = [self.availableNetworks containsObject:self.currentNetworkAdapter];
    if (available) {
        self.availableStatus.text = @"☑︎";
        self.availableStatus.textColor = [UIColor greenColor];
    } else {
        self.availableStatus.text = @"☒";
        self.availableStatus.textColor = [UIColor redColor];
    }

    BOOL initialized = [self.initializedNetworks containsObject:self.currentNetworkAdapter];
    if (initialized) {
        self.initializationStatus.text = @"☑︎";
        self.initializationStatus.textColor = [UIColor greenColor];
    } else {
        self.initializationStatus.text = @"☒";
        self.initializationStatus.textColor = [UIColor redColor];
    }
    
    if ([self.enabledNetworks containsObject:self.currentNetworkAdapter]) {
        self.enabledStatus.text = @"☑︎";
        self.enabledStatus.textColor = [UIColor greenColor];
    } else {
        self.enabledStatus.text = @"☒";
        self.enabledStatus.textColor = [UIColor redColor];
    }
    
    if (available && initialized) {
        [self makeAdControls];
    } else {
        [self.adControls removeFromSuperview];
    }
}

- (NSString *)countryCode{
    return @"us";
}

- (void)adapterWasClicked:(HZBaseAdapter *)adapter {

}

- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter {
    if (![self.currentNetworkAdapter hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] ||
        [[self.currentNetworkAdapter name] isEqualToString:@"admob"]) {
        self.showButton.backgroundColor = [UIColor redColor];
    } else {
        self.showButton.backgroundColor = [UIColor greenColor];
    }
}

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter {
    if (![self.currentNetworkAdapter hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] ||
        [[self.currentNetworkAdapter name] isEqualToString:@"admob"]) {
        self.showButton.backgroundColor = [UIColor redColor];
    }
}

- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter {
    if (![self.currentNetworkAdapter hasAdForType:self.currentAdType tag:[HeyzapAds defaultTagName]] ||
        [[self.currentNetworkAdapter name] isEqualToString:@"admob"]) {
        self.showButton.backgroundColor = [UIColor redColor];
    }
}

- (void)adapterWillPlayAudio:(HZBaseAdapter *)adapter {
    
}

- (void)adapterDidFinishPlayingAudio:(HZBaseAdapter *)adapter {
    
}

- (NSString *) humanizedNetworkName:(NSString *)network {
    NSDictionary *nameMap = @{
        @"adcolony": @"AdColony",
        @"admob":@"AdMob",
        @"applovin": @"AppLovin",
        @"chartboost": @"Chartboost",
        @"unityads": @"UnityAds",
        @"vungle": @"Vungle"
    };
    
    return [nameMap objectForKey:network];
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

@end