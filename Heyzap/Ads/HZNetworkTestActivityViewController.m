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
#import "HZNetworkTestActivityViewController.h"
#import "HZNetworkTestActivityNetworkViewController.h"
#import "HZDispatch.h"
#import "HZUnityAds.h"
#import "HZDictionaryUtils.h"
#import "HZDevice.h"
#import "HZAbstractHeyzapAdapter.h"
#import "HZMediationPersistentConfig.h"
#import "HZUtils.h"
#import "HZNetworkTestActivityTableViewCell.h"
#import "HZUINavigationController.h"

@interface HZNetworkTestActivityViewController() <HZMediationTestSuitePage>

@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) NSArray<Class> *allNetworks;
@property (nonatomic) NSSet<HZBaseAdapter *> *availableNetworks;
@property (nonatomic) NSSet<HZBaseAdapter *> *networksWithCredentials;
@property (nonatomic) NSSet<HZBaseAdapter *> *enabledNetworks;
@property (nonatomic) NSMutableArray<NSNumber *> *integrationStatuses;
@property (nonatomic) UILabel *chooseLabel;
@end

@implementation HZNetworkTestActivityViewController


#pragma mark - View lifecycle methods

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self.delegate didLoad:self];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self makeView];
    
    //fetch ad list
    [self checkNetworkInfo:self.refreshControl completion:nil];
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


#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allNetworks count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HZBaseAdapter *network = (HZBaseAdapter *)[[self.allNetworks objectAtIndex:indexPath.row] sharedAdapter];
    
    HZNetworkTestActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    
    if (cell == nil){
        cell = [[HZNetworkTestActivityTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"reuseIdentifier" persistentConfig:[HeyzapMediation sharedInstance].persistentConfig tableViewController:self];
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
    
    HZNetworkTestActivityNetworkViewController *networkVC = [[HZNetworkTestActivityNetworkViewController alloc] initWithNetwork:network
                                                                                                           rootVC:self.rootVC
                                                                                                        available:[self.availableNetworks containsObject:network]
                                                                                                   hasCredentials:[self.networksWithCredentials containsObject:network]
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
                                                                              self.tableView.frame.size.width - 20, 60)];
    
    // choose network label
    self.chooseLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.tableView.tableHeaderView.frame.origin.x + 10,
                                                                 self.tableView.tableHeaderView.frame.size.height - 32,
                                                                 140, 32)];
    self.chooseLabel.backgroundColor = [UIColor clearColor];
    self.chooseLabel.font = [UIFont systemFontOfSize:14];
    self.chooseLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    CGFloat buttonWidth = 50;
    
    UIButton *allOnButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    allOnButton.frame = CGRectMake(CGRectGetWidth(self.tableView.tableHeaderView.frame) - buttonWidth - 10, CGRectGetMidY(self.tableView.tableHeaderView.frame) - 20, buttonWidth, 40);
    [allOnButton addTarget:self action:@selector(allOnButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    allOnButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [allOnButton setTitle:@"All On" forState:UIControlStateNormal];
    [self.tableView.tableHeaderView addSubview:allOnButton];
    
    UIButton *allOffButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    allOffButton.frame = CGRectMake(CGRectGetMinX(allOnButton.frame) - buttonWidth - 10, CGRectGetMidY(self.tableView.tableHeaderView.frame) - 20, buttonWidth, 40);
    [allOffButton addTarget:self action:@selector(allOffButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    allOffButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [allOffButton setTitle:@"All Off" forState:UIControlStateNormal];
    [self.tableView.tableHeaderView addSubview:allOffButton];
    
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

- (void) infoButtonPressed {
    NSString *msg = @"You can test individual network integrations from this screen. The switches on the right allow you to disable individual networks on this device for testing purposes. Turning a network off here will also turn it off in your app until you turn it back on (this setting persists across app loads).";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Testing Individual Networks" message:msg delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
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
        NSMutableSet *networksWithCredentials = [NSMutableSet set];
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json];
        for (NSDictionary *mediator in networks) {
            BOOL available = NO;
            BOOL enabled = NO;
            BOOL hasCredentials = NO;
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
            
            if ([adapter hasNecessaryCredentials]) {
                hasCredentials = YES;
                [networksWithCredentials addObject:adapter];
            }
            
            // update this network's integration status
            NSUInteger index = [self.allNetworks indexOfObject:mediatorClass];
            self.integrationStatuses[index] = @(available && enabled && hasCredentials);
        }
        
        self.enabledNetworks = enabledNetworks;
        self.networksWithCredentials = networksWithCredentials;
        HZDLog(@"Networks available: %@", self.availableNetworks);
        HZDLog(@"Networks with credentials: %@", self.networksWithCredentials);
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
    return YES;
}

- (void) setAllNetworksEnabled:(BOOL)enabled {
    NSSet * allNetworkNames = [[NSSet alloc]initWithArray:hzMap(self.allNetworks, ^NSString *(Class klass){return [[klass sharedAdapter] name];})];
    if(enabled) {
        [[HeyzapMediation sharedInstance].persistentConfig removeDisabledNetworks:allNetworkNames];
    } else {
        [[HeyzapMediation sharedInstance].persistentConfig addDisabledNetworks:allNetworkNames];
    }
    
    [self.tableView reloadData];
}


- (void) allOffButtonPressed {
    [self setAllNetworksEnabled:NO];
}

- (void) allOnButtonPressed {
    [self setAllNetworksEnabled:YES];
}

@end