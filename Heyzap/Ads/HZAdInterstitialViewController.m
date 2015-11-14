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
#import "HZUtils.h"
#import "HZEnums.h"
#import "HZDevice.h"

@interface HZAdInterstitialViewController()

@property (nonatomic) HZWebView *webview;
@property (nonatomic) BOOL showOnReady;

@end

@implementation HZAdInterstitialViewController

// The superclass implements the storage for this property;
// @dynamic is needed to subclass `ad` to `HZInterstitialAdModel`
@dynamic ad;

- (id) initWithAd:(HZInterstitialAdModel *)ad {
    self = [super initWithAd: ad];
    if (self) {
        self.showOnReady = NO;
        self.webview = [[HZWebView alloc] initWithFrame: CGRectZero];
        self.webview.actionDelegate = self;
        self.webview.backgroundColor = [UIColor clearColor];
        [self.webview setHTML: self.ad.HTMLContent];
    }
    
    return self;
}

#pragma mark - Show/Hide
- (void) show {
    [super show];
}

- (void) showWithOptions:(HZShowOptions *)options {
    [super showWithOptions:options];
}

- (void) hide {
    [super hide];
}

#pragma mark - UIViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    BOOL forceRotation = NO;
    CGAffineTransform transformToApply = CGAffineTransformIdentity;
    if ([self needToTransformOrientation]) {
        forceRotation = YES;
        // app does not support the required orientation of the ad, so transform the view.
        
        UIInterfaceOrientation currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)) {
            // landscape device, portrait ad
            // transform should go to portrait (and not portrait upside down, since that's kinda weird)
            double rotation = currentInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ? M_PI_2 : -M_PI_2;
            transformToApply = CGAffineTransformMakeRotation(rotation);
        } else {
            // portrait device, landscape ad
            transformToApply = CGAffineTransformMakeRotation(M_PI_2);
        }
    }
    
    self.view.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.view.transform = transformToApply;
    [self.view setBackgroundColor: [UIColor clearColor]];
    self.webview.frame = self.view.bounds;
    self.webview.hidden = YES;
    self.webview.layer.opacity = 0.0f;
    
    // this is for iOS 6 or 7 only. ion iOS 8 and above, the transform done on `self.view` above changes its bounds,
    // which is then applied to `self.webView` and `self.videoView` above, so they always rotate to landscape if forceRotation is YES.
    if (forceRotation && self.ad.enable90DegreeTransform) {
        self.webview.transform = transformToApply;
    }
    
    [self.view addSubview: self.webview];
    
    [UIView animateWithDuration: 0.3 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
        self.webview.hidden = NO;
        self.webview.layer.opacity = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.webview.frame = self.view.bounds;
    
    [self didImpression];
}

#pragma mark - Orientation

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    // avoid this error: "Supported orientations has no common orientation with the application, and [HZAdInterstitialViewController shouldAutorotate] is returning YES."
    // only report the ad's orientation if the app supports it. Otherwise, report whatever is supported to avoid error, and do a transform on the view to properly show the ad.
    if ([[HZDevice currentDevice] applicationSupportsUIInterfaceOrientationMask:self.ad.requiredAdOrientation]) {
        return self.ad.requiredAdOrientation;
    } else {
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:[UIApplication sharedApplication].keyWindow];
    }
}

- (BOOL)shouldAutorotate {
    // don't autorotate if we transform the view from landscape->portrait or vice-versa, since the view is already presented against the device's orientation
    return ![self needToTransformOrientation];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (BOOL) needToTransformOrientation {
    UIInterfaceOrientationMask supportedInterfaceOrientations = [self supportedInterfaceOrientations];
    return !(supportedInterfaceOrientations & self.ad.requiredAdOrientation);
}

#pragma mark - Popup Action Delegate

- (void) onActionClick: (id) sender withURL:(NSURL *)url {
    [self didClickWithURL:url];
}

- (void) onActionCompleted: (id) sender {}

- (void) onActionError: (id) sender {
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
