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
#import "HZTestActivityViewController.h"
#import "HZTestActivityNetworkViewController.h"
#import "HZDispatch.h"
#import "HZUnityAds.h"
#import "HZDictionaryUtils.h"
#import "HZDevice.h"
#import "HZAbstractHeyzapAdapter.h"
#import "HZMediationPersistentConfig.h"
#import "HZUtils.h"
#import "HZTestActivityTableViewCell.h"
#import "HZUINavigationController.h"

@interface HZTestActivityViewController()

@property (nonatomic) BOOL statusBarHidden;
@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) NSArray<Class> *allNetworks;
@property (nonatomic) NSSet<HZBaseAdapter *> *availableNetworks;
@property (nonatomic) NSSet<HZBaseAdapter *> *initializedNetworks;
@property (nonatomic) NSSet<HZBaseAdapter *> *enabledNetworks;
@property (nonatomic) NSMutableArray<NSNumber *> *integrationStatuses;
@property (nonatomic) UILabel *chooseLabel;

@end

@implementation HZTestActivityViewController

#pragma mark - Test activity entry point

+ (void) show {
    HZDLog(@"Showing test activity view controller");
    
    [[HeyzapMediation sharedInstance] start];
    
    HZTestActivityViewController *vc = [[self alloc] init];
    
    // save whether the status bar is hidden
    vc.statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    // check for a root view controller
    vc.rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (!vc.rootVC) {
        HZDLog(@"Heyzap requires a root view controller to display the test activity. Set the `rootViewController` property of [UIApplication sharedApplication].keyWindow to fix this error. If you have any trouble doing this, contact support@heyzap.com");
        return;
    }
    
    // take over the screen
    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    HZUINavigationController *nav = [[HZUINavigationController alloc] initWithRootViewController:vc orientations:UIInterfaceOrientationMaskAll];
    [vc.rootVC presentViewController:nav animated:YES completion:nil];
}

#pragma mark - View lifecycle methods

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if([self.navigationController.navigationBar respondsToSelector:@selector(barTintColor)]){
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    }
    
    self.title = @"Heyzap Mediation Test";
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(hide)];
    [self.navigationItem setLeftBarButtonItem:button animated:NO];
    
    UISwitch *allNeworksEnableSwitch;
    if ([self showNetworkEnableSwitch]) {
        allNeworksEnableSwitch = [[UISwitch alloc] init];
        [allNeworksEnableSwitch addTarget:self action:@selector(allNetworksEnableSwitchToggled:) forControlEvents:UIControlEventValueChanged];
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithCustomView:allNeworksEnableSwitch]];
    }
    self.navigationController.navigationBar.titleTextAttributes = nil;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // disable segmentation for the test activity
    [[HeyzapMediation sharedInstance] enableSegmentation:NO];
    
    [self makeView];
    
    //fetch ad list
    [self checkNetworkInfo:self.refreshControl completion:^(BOOL success){
        // if more than half the networks are disabled already, default switch to off
        // else default to on
        [allNeworksEnableSwitch setOn:[[[HeyzapMediation sharedInstance].persistentConfig allDisabledNetworks] count] < (self.allNetworks.count/2)];
    }];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    HZDLog(@"Hiding test activity view controller");
    
    // re-enable segmentation after the test activity closes
    [[HeyzapMediation sharedInstance] enableSegmentation:YES];
    
    [self.rootVC dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarHidden];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allNetworks count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HZBaseAdapter *network = (HZBaseAdapter *)[[self.allNetworks objectAtIndex:indexPath.row] sharedAdapter];
    
    HZTestActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    
    if (cell == nil){
        cell = [[HZTestActivityTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"reuseIdentifier" persistentConfig:[HeyzapMediation sharedInstance].persistentConfig tableViewController:self];
    }
    
    [cell configureWithNetwork:network integratedSuccessfully:[self.integrationStatuses[indexPath.row] boolValue]];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Class networkClass = [self.allNetworks objectAtIndex:indexPath.row];
    if (![networkClass isSDKAvailable]) {
        [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ SDK is not available", [networkClass humanizedName]]
                                    message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    HZBaseAdapter *network = [networkClass sharedAdapter];
    HZDLog(@"Current network adapter: %@", network);
    
    HZTestActivityNetworkViewController *networkVC = [[HZTestActivityNetworkViewController alloc] initWithNetwork:network
                                                                                                           rootVC:self.rootVC
                                                                                                        available:[self.availableNetworks containsObject:network]
                                                                                                      initialized:[self.initializedNetworks containsObject:network]
                                                                                                          enabled:[self.enabledNetworks containsObject:network]];
    
    [self.navigationController pushViewController:networkVC animated:YES];
}

// To get rid of empty rows at the bottom
// from: http://stackoverflow.com/a/5377569

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create an "invisible" footer
    return 0.01f;
}

#pragma mark - View creation utility methods

- (void) makeView {
    // network table
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x + 10,
                                                                              self.tableView.frame.origin.y,
                                                                              self.tableView.frame.size.width - 10, 32)];
    
    // choose network label
    self.chooseLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x + 10,
                                                                 self.tableView.frame.origin.y,
                                                                 self.tableView.frame.size.width - 10, 32)];
    self.chooseLabel.backgroundColor = [UIColor clearColor];
    self.chooseLabel.font = [UIFont systemFontOfSize:12];
    self.chooseLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if (self.availableNetworks.count == 0) {
        self.chooseLabel.text = @"No SDKs are available";
    } else {
        self.chooseLabel.text = @"Choose a network:";
    }
    
    [self.tableView.tableHeaderView addSubview:self.chooseLabel];
    [self.tableView reloadData];
    
    //refresh spinner
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(checkNetworkInfo:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl beginRefreshing];
}


#pragma mark - General utility methods

- (void) checkNetworkInfo:(UIRefreshControl *)refreshControl {
    [self checkNetworkInfo:refreshControl completion:nil];
}
- (void) checkNetworkInfo:(UIRefreshControl *)refreshControl completion:(void (^)(BOOL success))completion {
    
    // check available
    NSMutableSet *availableNetworks = [NSMutableSet set];
    for (HZBaseAdapter *adapter in [[HeyzapMediation sharedInstance] availableAdaptersWithHeyzap:YES]) {
        [availableNetworks addObject:[[adapter class] sharedAdapter]];
    }
    self.availableNetworks = availableNetworks;
    self.chooseLabel.text = @"Loading...";
    
    [[HZMediationAPIClient sharedClient] GET:@"info" parameters:nil success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
        
        // get networks and their integration statuses when fetching for the first time
        if (!self.allNetworks) {
            
            // get the list of all networks
            self.allNetworks = [HZBaseAdapter testActivityAdapters];
            HZDLog(@"All networks: %@", self.allNetworks);
        }
        
        if (!self.integrationStatuses) {
            
            // this will link network names to their labels, so we can update the check/cross if necessary
            self.integrationStatuses = [NSMutableArray array];
            for (NSUInteger i = 0; i < [self.allNetworks count]; i++) {
                [self.integrationStatuses addObject:@NO];
            }
        }
        
        NSMutableSet *enabledNetworks = [NSMutableSet set];
        NSMutableSet *initializedNetworks = [NSMutableSet set];
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json];
        for (NSDictionary *mediator in networks) {
            BOOL available = NO;
            BOOL enabled = NO;
            BOOL initialized = NO;
            NSString *mediatorName = mediator[@"name"];
            
            Class mediatorClass = [HZBaseAdapter adapterClassForName:mediatorName];
            
            if ([self.allNetworks indexOfObjectIdenticalTo:mediatorClass] == NSNotFound) {
                continue;
            }
            
            // don't do anything if the sdk isn't available
            if (![mediatorClass isSDKAvailable]) {
                continue;
            } else {
                available = YES;
            }
            
            HZBaseAdapter *adapter = [mediatorClass sharedAdapter];
            
            // check enabled
            if([mediator[@"enabled"] boolValue]){
                [enabledNetworks addObject:adapter];
                enabled = YES;
            }
            
            // check original initialization succeeded
            
            if ([[HeyzapMediation sharedInstance] isAdapterInitialized:adapter]
                || [adapter isKindOfClass:[HZAbstractHeyzapAdapter class]]) {
                initialized = YES;
                [initializedNetworks addObject:adapter];
            }
            
            // update this network's integration status
            NSUInteger index = [self.allNetworks indexOfObject:mediatorClass];
            self.integrationStatuses[index] = @(available && enabled && initialized);
        }
        
        self.enabledNetworks = enabledNetworks;
        self.initializedNetworks = initializedNetworks;
        HZDLog(@"Networks available: %@", self.availableNetworks);
        HZDLog(@"Networks initialized: %@", self.initializedNetworks);
        HZDLog(@"Networks enabled: %@", self.enabledNetworks);
        
        // update the table view, so that the checkboxes can change if necessary
        [self.tableView reloadData];
        
        // update the message that either says "No SDKs are available" or says "Choose a network"
        if (self.availableNetworks.count == 0) {
            self.chooseLabel.text = @"No SDKs are available";
        } else {
            self.chooseLabel.text = @"Choose a network:";
        }
        
        [refreshControl endRefreshing];
        if(completion) {
            completion(YES);
        }
        
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        
        [refreshControl endRefreshing];
        self.chooseLabel.text = @"Error getting Ad Networks";
        
        [[[UIAlertView alloc] initWithTitle:@"Unable to get Ad Networks"
                                    message:@"Please make sure you are connected to the internet and refresh the list. If the error persists, contact support@heyzap.com."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil]
         show];
        
        HZDLog(@"Error from /info: %@", error.localizedDescription);
        if(completion) {
            completion(NO);
        }
    }];
}
     
#pragma mark - Network enable/disable
     
- (BOOL) showNetworkEnableSwitch {
    return [HZDevice isHeyzapTestApp];
}

- (void)allNetworksEnableSwitchToggled:(UISwitch *)theSwitch {
    NSSet * allNetworkNames = [[NSSet alloc]initWithArray:hzMap(self.allNetworks, ^NSString *(Class klass){return [[klass sharedAdapter] name];})];
    if(theSwitch.isOn) {
        [[HeyzapMediation sharedInstance].persistentConfig removeDisabledNetworks:allNetworkNames];
    } else {
        [[HeyzapMediation sharedInstance].persistentConfig addDisabledNetworks:allNetworkNames];
    }
    
    [self.tableView reloadData];
}

@end