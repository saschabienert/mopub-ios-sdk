//
//  MediationTestAppViewController.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/10/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "MediationTestAppViewController.h"
#import "HZInterstitialAd.h"

@interface MediationTestAppViewController ()

@end

@implementation MediationTestAppViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *showInterstitialButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:@"Show Interstial" forState:UIControlStateNormal];
        button.frame = CGRectMake(20, 20, 120, 44);
        [button addTarget:self
                   action:@selector(showInterstitialTapped)
         forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:showInterstitialButton];
}

- (void)showInterstitialTapped
{
//    [HZInterstitialAd showO];
}

@end
