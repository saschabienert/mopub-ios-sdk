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

@interface HZTestActivityViewController() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) BOOL statusBarHidden;
@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) NSArray *allNetworks;
@property (nonatomic) NSSet *availableNetworks;
@property (nonatomic) NSSet *initializedNetworks;
@property (nonatomic) NSSet *enabledNetworks;
@property (nonatomic) NSMutableDictionary *integrationStatusHash;

@end

@implementation HZTestActivityViewController

#pragma mark - Test activity entry point

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
    vc.allNetworks = [[nonHeyzapNetworks allObjects] sortedArrayUsingComparator:^NSComparisonResult(HZBaseAdapter *obj1, HZBaseAdapter *obj2) {
        return [[obj1 name] compare:[obj2 name]];
    }];
    NSLog(@"All networks: %@", vc.allNetworks);
    
    // get the networks' enabled status and credentials to build sets of enabled and initialized networks
    vc.integrationStatusHash = [NSMutableDictionary dictionary];
    [vc checkNetworkInfo];

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
    NSLog(@"Hiding test activity view controller");
    
    [self.rootVC dismissViewControllerAnimated:YES completion:^{
        // reset the root view controller
        [[[UIApplication sharedApplication] keyWindow] setRootViewController:self.rootVC];
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarHidden];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allNetworks count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HZBaseAdapter *network = [[self.allNetworks objectAtIndex:indexPath.row] sharedInstance];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"reuseIdentifier"];
    }
    cell.textLabel.text = [[network class] humanizedName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    [self.integrationStatusHash setValue:cell forKey:[[network class] name]];

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    HZBaseAdapter *network = [[[self.allNetworks objectAtIndex:indexPath.row] class] sharedInstance];
    NSLog(@"Current network adapter: %@", network);
    
    HZTestActivityNetworkViewController *networkVC = [[HZTestActivityNetworkViewController alloc] initWithNetwork:network
                                                                                                           rootVC:self.rootVC
                                                                                                        available:[self.availableNetworks containsObject:network]
                                                                                                      initialized:[self.initializedNetworks containsObject:network]
                                                                                                          enabled:[self.enabledNetworks containsObject:network]];
    [self presentViewController:networkVC animated:YES completion:^{
        // some adapters (AdMob, Vungle) attempt to display their ads on the root view controller, so set it
        [[[UIApplication sharedApplication] keyWindow] setRootViewController:networkVC];
    }];
}

#pragma mark - View creation utility methods

- (UIView *) makeView {
    UIView *chooseNetworkView = [[UIView alloc] initWithFrame:self.view.frame];
    
    // header
    UINavigationBar *header = ({
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame:CGRectMake(chooseNetworkView.frame.origin.x, chooseNetworkView.frame.origin.y,
                                                                                 chooseNetworkView.frame.size.width, 44)];
        nav.barTintColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
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
    UILabel *chooseLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(chooseNetworkView.frame.origin.x + 10, chooseNetworkView.frame.origin.y + header.frame.size.height,
                                                                   chooseNetworkView.frame.size.width - 10, 32)];
        label.text = @"Choose a network:";
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label;
    });
    [chooseNetworkView addSubview:chooseLabel];
    
    // networks table view
    UITableView *networksTableView = ({
        UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(chooseNetworkView.frame.origin.x,
                                                                           chooseNetworkView.frame.origin.y + header.frame.size.height + chooseLabel.frame.size.height,
                                                                           chooseNetworkView.frame.size.width, chooseNetworkView.frame.size.height - chooseLabel.frame.size.height)
                                                          style:UITableViewStylePlain];
        table.backgroundColor = [UIColor clearColor];
        table.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        table.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        table.delegate = self;
        table.dataSource = self;
        table;
    });
    [networksTableView reloadData];
    [chooseNetworkView addSubview:networksTableView];
    
    return chooseNetworkView;
}

- (void) updateIntegrationStatus:(HZBaseAdapter *)network {
    UITableViewCell *cell = self.integrationStatusHash[[[network class] name]];

    if ([self.availableNetworks containsObject:network] && [self.initializedNetworks containsObject:network] && [self.enabledNetworks containsObject:network]) {
        cell.detailTextLabel.text = @"☑︎";
        cell.detailTextLabel.textColor = [UIColor greenColor];
    } else {
        cell.detailTextLabel.text = @"☒";
        cell.detailTextLabel.textColor = [UIColor redColor];
    }
}

#pragma mark - General utility methods

- (void) checkNetworkInfo {
    // check available
    NSMutableSet *availableNetworks = [NSMutableSet set];
    for (HZBaseAdapter *adapter in [HeyzapMediation availableNonHeyzapAdapters]) {
        [availableNetworks addObject:[[adapter class] sharedInstance]];
    }
    self.availableNetworks = availableNetworks;

    [[HZMediationAPIClient sharedClient] get:@"info" withParams:nil success:^(NSDictionary *json) {
        NSMutableSet *enabledNetworks = [NSMutableSet set];
        NSMutableSet *initializedNetworks = [NSMutableSet set];
        NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:json];
        for (NSDictionary *mediator in networks) {
            NSString *mediatorName = mediator[@"name"];

            if (![mediatorName isEqualToString:@"heyzap"]) {
                Class mediatorClass = [HZBaseAdapter adapterClassForName:mediatorName];
                HZBaseAdapter *adapter = [mediatorClass sharedInstance];
                
                // check enabled
                if([mediator[@"enabled"] boolValue]){
                    [enabledNetworks addObject:adapter];
                }
                
                // check original initialization succeeded
                if (adapter.credentials) {
                    [initializedNetworks addObject:adapter];
                }

                // update the check/cross for this network
                [self updateIntegrationStatus:[mediatorClass sharedInstance]];
            }
        }
        self.enabledNetworks = enabledNetworks;
        self.initializedNetworks = initializedNetworks;
        NSLog(@"Networks available: %@", self.availableNetworks);
        NSLog(@"Networks initialized: %@", self.initializedNetworks);
        NSLog(@"Networks enabled: %@", self.enabledNetworks);
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error from /info: %@", error);
    }];
}

@end