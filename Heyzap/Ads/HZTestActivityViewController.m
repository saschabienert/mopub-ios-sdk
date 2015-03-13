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
#import "HZTestActivityNetworkViewController.h"
#import "HZDispatch.h"
#import "HZUnityAds.h"
#import "HZDictionaryUtils.h"
#import "HZDevice.h"
#import "HZCrossPromoAdapter.h"

@interface HZTestActivityViewController() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) BOOL statusBarHidden;
@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) NSArray *allNetworks;
@property (nonatomic) NSSet *availableNetworks;
@property (nonatomic) NSSet *initializedNetworks;
@property (nonatomic) NSSet *enabledNetworks;
@property (nonatomic) NSMutableArray *integrationStatuses;
@property (nonatomic) UILabel *chooseLabel;
@property (nonatomic) UITableView *networksTableView;

@end

@implementation HZTestActivityViewController

#pragma mark - Test activity entry point

+ (void) show {
    HZDLog(@"Showing test activity view controller");

    HZTestActivityViewController *vc = [[self alloc] init];
    
    // save whether the status bar is hidden
    vc.statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    // check for a root view controller
    vc.rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (!vc.rootVC) {
        HZDLog(@"Heyzap requires a root view controller to display the test activity. Set the `rootViewController` property of [UIApplication sharedApplication].keyWindow to fix this error. If you have any trouble doing this, contact support@heyzap.com");
        return;
    }

    // get the list of all networks
    vc.allNetworks = [HZBaseAdapter testActivityAdapters];
    HZDLog(@"All networks: %@", vc.allNetworks);
    
    // this will link network names to their labels, so we can update the check/cross if necessary
    vc.integrationStatuses = [NSMutableArray array];
    for (NSUInteger i = 0; i < [vc.allNetworks count]; i++) {
        [vc.integrationStatuses addObject:@NO];
    }

    // take over the screen
    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    [vc.rootVC presentViewController:vc animated:YES completion:nil];
}

#pragma mark - View lifecycle methods

- (void) viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
 
    [self.view addSubview:[self makeView]];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // check network info again, so that if we switch back to a network that has been refreshed we don't forget the new state
    [self checkNetworkInfo];
}


#pragma mark - UI action methods

- (void) hide {
    HZDLog(@"Hiding test activity view controller");
    
    [self.rootVC dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarHidden];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allNetworks count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HZBaseAdapter *network = (HZBaseAdapter *)[[self.allNetworks objectAtIndex:indexPath.row] sharedInstance];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"reuseIdentifier"];
    }
    cell.textLabel.text = [[network class] humanizedName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([self.integrationStatuses[indexPath.row] boolValue]) {
        cell.detailTextLabel.text = @"☑︎";
        cell.detailTextLabel.textColor = [UIColor greenColor];
    } else {
        cell.detailTextLabel.text = @"☒";
        cell.detailTextLabel.textColor = [UIColor redColor];
    }

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    HZBaseAdapter *network = (HZBaseAdapter *)[[[self.allNetworks objectAtIndex:indexPath.row] class] sharedInstance];
    HZDLog(@"Current network adapter: %@", network);
    
    HZTestActivityNetworkViewController *networkVC = [[HZTestActivityNetworkViewController alloc] initWithNetwork:network
                                                                                                           rootVC:self.rootVC
                                                                                                        available:[self.availableNetworks containsObject:network]
                                                                                                      initialized:[self.initializedNetworks containsObject:network]
                                                                                                          enabled:[self.enabledNetworks containsObject:network]];
    [self presentViewController:networkVC animated:YES completion:nil];
}

#pragma mark - View creation utility methods

- (UIView *) makeView {
    UIView *chooseNetworkView = [[UIView alloc] initWithFrame:self.view.frame];
    chooseNetworkView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    // header
    UINavigationBar *header = ({
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame:CGRectMake(chooseNetworkView.frame.origin.x, chooseNetworkView.frame.origin.y,
                                                                                 chooseNetworkView.frame.size.width, 44)];
        if([nav respondsToSelector:@selector(barTintColor)]){
            nav.barTintColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
        }
        nav.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        nav;
    });
    [[UINavigationBar appearance] setTitleTextAttributes:@{ UITextAttributeFont: [UIFont systemFontOfSize:18] }];
    
    // title and back button
    UINavigationItem *headerTitle = ({
        UINavigationItem *title = [[UINavigationItem alloc] initWithTitle:@"Heyzap Mediation Test"];
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(hide)];
        title.leftBarButtonItem = button;
        title;
    });
    [header setItems:[NSArray arrayWithObject:headerTitle]];

    [chooseNetworkView addSubview:header];
    
    // choose network label
    self.chooseLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(chooseNetworkView.frame.origin.x + 10, chooseNetworkView.frame.origin.y + header.frame.size.height,
                                                                   chooseNetworkView.frame.size.width - 10, 32)];
        if (self.availableNetworks.count == 0) {
            label.text = @"No SDKs are available";
        } else {
            label.text = @"Choose a network:";
        }
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [chooseNetworkView addSubview:self.chooseLabel];
    
    // networks table view
    self.networksTableView = ({
        UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(chooseNetworkView.frame.origin.x,
                                                                           chooseNetworkView.frame.origin.y + header.frame.size.height + self.chooseLabel.frame.size.height,
                                                                           chooseNetworkView.frame.size.width, chooseNetworkView.frame.size.height - self.chooseLabel.frame.size.height)
                                                          style:UITableViewStylePlain];
        table.backgroundColor = [UIColor clearColor];
        table.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        table.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        table.delegate = self;
        table.dataSource = self;
        table;
    });
    [self.networksTableView reloadData];
    [chooseNetworkView addSubview:self.networksTableView];
    
    return chooseNetworkView;
}

#pragma mark - General utility methods

- (void) checkNetworkInfo {
    // check available
    NSMutableSet *availableNetworks = [NSMutableSet set];
    for (HZBaseAdapter *adapter in [HeyzapMediation availableAdaptersWithHeyzap:YES]) {
        [availableNetworks addObject:[[adapter class] sharedInstance]];
    }
    self.availableNetworks = availableNetworks;

    [[HZMediationAPIClient sharedClient] get:@"info" withParams:nil success:^(NSDictionary *json) {
        NSMutableSet *enabledNetworks = [NSMutableSet set];
        NSMutableSet *initializedNetworks = [NSMutableSet set];
        NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:json];
        for (NSDictionary *mediator in networks) {
            BOOL available = NO;
            BOOL enabled = NO;
            BOOL initialized = NO;
            NSString *mediatorName = mediator[@"name"];

            Class mediatorClass = [HZBaseAdapter adapterClassForName:mediatorName];

            // don't do anything if the sdk isn't available
            if (![mediatorClass isSDKAvailable]) {
                continue;
            } else {
                available = YES;
            }

            HZBaseAdapter *adapter = (HZBaseAdapter *)[mediatorClass sharedInstance];

            // check enabled
            if([mediator[@"enabled"] boolValue]){
                [enabledNetworks addObject:adapter];
                enabled = YES;
            }

            // check original initialization succeeded
            if (adapter.credentials) {
                [initializedNetworks addObject:adapter];
                initialized = YES;
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
        [self.networksTableView reloadData];

        // update the message that either says "No SDKs are available" or says "Choose a network"
        if (self.availableNetworks.count == 0) {
            self.chooseLabel.text = @"No SDKs are available";
        } else {
            self.chooseLabel.text = @"Choose a network:";
        }

    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        HZDLog(@"Error from /info: %@", error.localizedDescription);
    }];
}

@end