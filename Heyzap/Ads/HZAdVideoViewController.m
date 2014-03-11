//
//  HZAdVideoController.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdVideoViewController.h"
#import "HZVideoView.h"
#import "HZWebView.h"
#import "HZVideoAdModel.h"
#import "HZAdsManager.h"

#define kHZVideoViewTag 1
#define kHZWebViewTag 2

@interface HZAdVideoViewController ()<HZAdPopupActionDelegate>
@property (nonatomic) HZWebView *webView;
@property (nonatomic) HZVideoView *videoView;
@property (nonatomic, assign) BOOL showOnReady;
@property (nonatomic, assign) BOOL didFinishVideo;
@end

@implementation HZAdVideoViewController

- (id) initWithAd:(HZVideoAdModel *)ad {
    self = [super initWithAd: ad];
    if (self) {
        _didFinishVideo = NO;
        
        _videoView = [[HZVideoView alloc] initWithFrame: CGRectZero];
        _videoView.tag = kHZVideoViewTag;
        [_videoView setVideoURL: [self.ad URLForVideo]];
        _videoView.actionDelegate = self;
        
        [_videoView setSkipButton: self.ad.allowSkip];
        [_videoView setHideButton: self.ad.allowHide];
        [_videoView setSkipButtonTimeInterval: [self.ad.lockoutTime doubleValue]/1000.0];
        
        _webView = [[HZWebView alloc] initWithFrame: CGRectZero];
        _webView.tag = kHZWebViewTag;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.actionDelegate = self;
        
        [_webView setHTML: self.ad.HTMLContent];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationDidEnterForeground:) name: UIApplicationDidBecomeActiveNotification object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationDidEnterBackground:) name: UIApplicationDidEnterBackgroundNotification object: nil];
        
    }
    return self;
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    self.videoView = nil;
    self.webView = nil;
    self.ad = nil;
}

- (void) show {
    if ([[HZAdsManager sharedManager].statusDelegate respondsToSelector:@selector(willStartAudio)]) {
        [[HZAdsManager sharedManager].statusDelegate willStartAudio];
    }
    
    [super show];
}

- (void) hide {
    [self.ad onCompleteWithViewDuration: self.videoView.playbackTime andTotalDuration: self.videoView.videoDuration andFinished: self.didFinishVideo];
    
    if (self.ad.adUnit != nil && [self.ad.adUnit isEqualToString: @"incentivized"]) {

        if (self.didFinishVideo) {
            [self.ad onIncentiveComplete];
        }
        
        if (self.didFinishVideo) {
            if ([[HZAdsManager sharedManager].incentivizedDelegate respondsToSelector:@selector(didCompleteAd)]) {
                [[HZAdsManager sharedManager].incentivizedDelegate didCompleteAd];
            }
        } else {
            if ([[HZAdsManager sharedManager].incentivizedDelegate respondsToSelector:@selector(didFailToCompleteAd)]) {
                [[HZAdsManager sharedManager].incentivizedDelegate didFailToCompleteAd];
            }
        }
        
    }
    
    [super hide];
}

- (void) switchToViewWithTag: (int) tag {
    switch(tag) {
        case kHZWebViewTag:
            [self.view bringSubviewToFront: self.webView];
            if ([[HZAdsManager sharedManager].statusDelegate respondsToSelector:@selector(didFinishAudio)]) {
                [[HZAdsManager sharedManager].statusDelegate didFinishAudio];
            }
            break;
        case kHZVideoViewTag:
        default:
            if ([[HZAdsManager sharedManager].statusDelegate respondsToSelector:@selector(willStartAudio)]) {
                [[HZAdsManager sharedManager].statusDelegate willStartAudio];
            }
            [self.view bringSubviewToFront: self.videoView];
            break;
    }
}

#pragma mark - UIViewController methods

- (void) viewDidLoad {
    [super viewDidLoad];
    
    BOOL forceRotation = NO;
    CGAffineTransform ninetyDegreeTransform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
    if (![self applicationSupportsLandscape]) {
        forceRotation = YES;
    }
    
    if (forceRotation) {
        self.view.transform = ninetyDegreeTransform;
    }
    
    self.view.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.view.backgroundColor = [UIColor clearColor];
    
    self.webView.frame = self.view.bounds;
    self.webView.hidden = YES;
    self.webView.layer.opacity = 0.0f;
    self.videoView.frame = self.view.bounds;
    self.videoView.hidden = YES;
    self.videoView.layer.opacity = 0.0f;
    
    if (forceRotation) {
        self.videoView.transform = ninetyDegreeTransform;
        self.webView.transform = ninetyDegreeTransform;
    }
    
    [self.view addSubview: self.webView];
    [self.view addSubview: self.videoView];

    [UIView animateWithDuration: 0.3 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
        self.webView.hidden = NO;
        self.webView.layer.opacity = 1.0f;
        self.videoView.hidden = NO;
        self.videoView.layer.opacity = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    self.videoView.frame = self.view.bounds;
    self.webView.frame = self.view.bounds;
    
    if ([self.view.subviews lastObject] == self.videoView) {
        [self.videoView play];
    }
}

- (void) viewDidUnload {
    [super viewDidUnload];
    
    [self.videoView removeFromSuperview];
    [self.webView removeFromSuperview];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void) viewWillUnload {
    [super viewWillUnload];
}

#pragma mark - Autorotation

- (NSUInteger)supportedInterfaceOrientations {
    if ([self applicationSupportsLandscape]) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: self.window];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    if ([self applicationSupportsLandscape]) {
//        return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
//    } else {
//        
//        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: self.window];
//    }
//}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft  || interfaceOrientation ==  UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Callbacks

- (void) onActionHide: (UIView *) sender {
    switch (sender.tag) {
        case kHZVideoViewTag:
            if (self.ad.postRollInterstitial) {
                [self.videoView pause];
                [self switchToViewWithTag: kHZWebViewTag];
            } else {
                [self hide];
            }
            break;
        case kHZWebViewTag:
        default:
            [self hide];
            break;
    }
}

- (void) onActionShow: (UIView *) sender {
    if (sender.tag == kHZVideoViewTag) {
        [self didImpression];
    }
}

- (void) onActionReady: (UIView *) sender {
    
}

- (void) onActionClick: (UIView *) sender withURL: (NSURL *) url {
    if ([sender tag] == kHZVideoViewTag) {
        if ([self.ad allowClick]) {
            [self.videoView pause];
            [self didClickWithURL: url];
        }
    }
    
    if ([sender tag] == kHZWebViewTag) {
        [self didClickWithURL: url];
    }
}

- (void) onActionCompleted: (UIView *) sender {
    if (sender.tag == kHZVideoViewTag) {
        self.didFinishVideo = YES;
        [self switchToViewWithTag: kHZWebViewTag];
    }
}


- (void) onActionError: (UIView *) sender {
    if (sender.tag == kHZVideoViewTag && self.ad.postRollInterstitial) {
        [self switchToViewWithTag: kHZWebViewTag];
    } else {
        [self hide];
    }
}

- (void) onActionRestart: (UIView *) sender {
    if (sender.tag == kHZWebViewTag) {
        [self switchToViewWithTag: kHZVideoViewTag];
    } else {
        //WTF?
    }
}

- (void) onActionInstallHeyzap: (id) sender {
    [self didClickHeyzapInstall];
}

- (void) applicationDidEnterForeground: (id) notification {
    if ([self.view.subviews lastObject] == self.videoView) {
        [self.videoView play];
    }
}

- (void) applicationDidEnterBackground: (id) notification {
    [self.videoView pause];
}

@end
