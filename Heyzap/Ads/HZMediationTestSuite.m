//
//  HZMediationTestSuite.m
//  Heyzap
//
//  Created by Monroe Ekilah on 10/12/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediationTestSuite.h"

#import "HeyzapMediation.h"
#import "HZMediationTestActivityViewController.h"
#import "HZNetworkTestActivityViewController.h"
#import "HZUINavigationController.h"

@interface HZMediationTestSuite ()
@property (nonatomic) BOOL statusBarHiddenBefore;
@property (nonatomic) UIViewController *rootVC;
@property (nonatomic) HZUINavigationController *navController;
@property (nonatomic) NSArray<id<HZMediationTestSuitePage>> *pages;
@property (nonatomic, copy) void (^completion)();
@end

@implementation HZMediationTestSuite


- (void) showWithCompletion:(void (^)())completion {
    self.completion = completion;
    
    HZMediationTestActivityViewController *mediationTestController = [[HZMediationTestActivityViewController alloc] init];
    HZNetworkTestActivityViewController *networkTestController = [[HZNetworkTestActivityViewController alloc] init];
    
    self.pages = @[mediationTestController, networkTestController];
    for( id<HZMediationTestSuitePage> page in self.pages) {
        [page setDelegate:self];
    }
    
    SDCSegmentedViewController *segmentedController = [[SDCSegmentedViewController alloc] initWithViewControllers:@[networkTestController, mediationTestController] titles:@[ @"Individual Networks", @"Mediation"]];
    
    if ([segmentedController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        segmentedController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    segmentedController.position = SDCSegmentedViewControllerControlPositionNavigationBar;
    
    self.navController = [[HZUINavigationController alloc] initWithRootViewController: segmentedController orientations:UIInterfaceOrientationMaskAll];
    
    // save whether the status bar is hidden
    self.statusBarHiddenBefore = [UIApplication sharedApplication].statusBarHidden;
    
    // check for a root view controller
    self.rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (!self.rootVC) {
        HZDLog(@"Heyzap requires a root view controller to display the test activity. Set the `rootViewController` property of [UIApplication sharedApplication].keyWindow to fix this error. If you have any trouble doing this, contact support@heyzap.com");
        return;
    }
    
    // take over the screen
    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    [self.rootVC presentViewController:self.navController animated:YES completion:nil];
    
}

- (void) didLoad:(UIViewController<HZMediationTestSuitePage> *)vc {
    if([vc.navigationController.navigationBar respondsToSelector:@selector(barTintColor)]){
        vc.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    }
    
    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:vc action:@selector(infoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *infoButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    [vc.navigationItem setRightBarButtonItem:infoButtonItem animated:NO];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(hide)];
    [vc.navigationItem setLeftBarButtonItem:button animated:NO];
    
    vc.navigationController.navigationBar.titleTextAttributes = nil;
}


#pragma mark - UI action methods

- (void) hide {
    for(id<HZMediationTestSuitePage> page in self.pages) {
        if ([page respondsToSelector:@selector(hide)]) {
            [page hide];
        }
    }
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarHiddenBefore];
    
    self.pages = nil;
    if (self.completion) {
        self.completion();
    }
}

@end