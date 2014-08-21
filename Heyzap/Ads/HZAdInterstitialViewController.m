//
//  HZAdInterstitialController.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdInterstitialViewController.h"
#import "HZWebView.h"
#import "HZInterstitialAdModel.h"
#import "HZAdsManager.h"
#import "HZInterstitialAd.h"
#import "HZMetrics.h"

@interface HZAdInterstitialViewController()

@property (nonatomic) HZWebView *webview;
@property (nonatomic, assign) BOOL showOnReady;

@end

@implementation HZAdInterstitialViewController

- (id) initWithAd:(HZInterstitialAdModel *)ad {
    self = [super initWithAd: ad];
    if (self) {
        self.showOnReady = NO;
        self.webview = [[HZWebView alloc] initWithFrame: CGRectZero];
        self.webview.actionDelegate = self;
        self.webview.backgroundColor = [UIColor clearColor];
        [self.webview setHTML: self.ad.HTMLContent];
        [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:@"fully-cached" tag:self.ad.tag type:self.ad.adUnit];
    }
    
    return self;
}

#pragma mark - Show/Hide
- (void) show {
    [super show];
}

- (void) hide {
    [super hide];
}

#pragma mark - UIViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view setBackgroundColor: [UIColor clearColor]];
    self.webview.frame = self.view.bounds;
    self.webview.hidden = YES;
    self.webview.layer.opacity = 0.0f;
    [self.view addSubview: self.webview];
    
    [UIView animateWithDuration: 0.3 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
        self.webview.hidden = NO;
        self.webview.layer.opacity = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
}

- (void) viewDidAppear:(BOOL)animated {
    self.webview.frame = self.view.bounds;
    
    [self didImpression];
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations {
    return self.ad.requiredAdOrientation;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Popup Action Delegate

- (void) onActionClick: (id) sender withURL:(NSURL *)url {
    [self didClickWithURL: url];
}

- (void) onActionCompleted: (id) sender {}

- (void) onActionError: (id) sender {
    [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kAdFailedToLoadValue tag:self.ad.tag type:self.ad.adUnit];
    
    [self hide];
}

- (void) onActionHide: (id) sender {
    [self hide];
}

- (void) onActionInstallHeyzap: (id) sender {
    [self didClickHeyzapInstall];
}

- (void) onActionReady: (id) sender {}

- (void) onActionRestart: (id) sender {}

- (void) onActionShow: (id) sender {}

@end
