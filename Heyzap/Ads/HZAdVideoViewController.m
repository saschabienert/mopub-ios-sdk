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
#import "HZMetrics.h"
#import "HZUtils.h"
#import "HZEnums.h"

#define kHZVideoViewTag 1
#define kHZWebViewTag 2

@interface HZAdVideoViewController ()<HZAdPopupActionDelegate>
@property (nonatomic) HZWebView *webView;
@property (nonatomic) HZVideoView *videoView;
@property (nonatomic, assign) BOOL showOnReady;
@property (nonatomic, assign) BOOL didFinishVideo;
@property (nonatomic, assign) BOOL didStartVideo;
@end

@implementation HZAdVideoViewController

- (id) initWithAd:(HZVideoAdModel *)ad {
    self = [super initWithAd: ad];
    if (self) {
        _didFinishVideo = NO;
        
        _videoView = [[HZVideoView alloc] initWithFrame: CGRectZero];
        _videoView.tag = kHZVideoViewTag;
        
        if (ad.fileCached || ad.allowFallbacktoStreaming || ad.forceStreaming) {
            [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kFullyCachedValue withProvider:self.ad network:HeyzapAdapterFromHZAuctionType(self.ad.auctionType)];
            if (![_videoView setVideoURL: [self.ad URLForVideo]]) {
                return nil;
            }
        } else {
            [ad onInterstitialFallback];
            [self didImpression];
        }
        
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
        
        _didStartVideo = NO;
        
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
    [super show];
}

- (void) showWithOptions:(HZShowOptions *)options {
    [super showWithOptions:options];
}

- (void) hide {
    [self.ad onCompleteWithViewDuration: self.videoView.playbackTime andTotalDuration: self.videoView.videoDuration andFinished: self.didFinishVideo];
    
    if (self.ad.adUnit != nil && [self.ad.adUnit isEqualToString: @"incentivized"]) {
        if (self.didFinishVideo) {
            [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didCompleteAdWithTag:self.ad.tag];
            [HZAdsManager postNotificationName:kHeyzapDidCompleteIncentivizedAd infoProvider:self.ad];
        } else {
            [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didFailToCompleteAdWithTag:self.ad.tag];
            [HZAdsManager postNotificationName:kHeyzapDidFailToCompleteIncentivizedAd infoProvider:self.ad];
        }
        
    }
    
    [super hide];
}

- (void) switchToViewWithTag: (int) tag {
    switch(tag) {
        case kHZWebViewTag:
            [self.view bringSubviewToFront: self.webView];
            break;
        case kHZVideoViewTag:
        default:
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
    
    if (forceRotation && self.ad.enable90DegreeTransform) {
        self.videoView.transform = ninetyDegreeTransform;
        self.webView.transform = ninetyDegreeTransform;
    }
    
    [self.view addSubview: self.webView];
    if (self.ad.fileCached || self.ad.allowFallbacktoStreaming || self.ad.forceStreaming) {
        [self.view addSubview: self.videoView];
    }

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
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:[UIApplication sharedApplication].keyWindow];
    }
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft  || interfaceOrientation ==  UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Callbacks

- (void) onActionHide: (UIView *) sender {
    [[HZMetrics sharedInstance] logMetricsEvent:kCloseClickedKey value:@1 withProvider:self.ad network:HeyzapAdapterFromHZAuctionType(self.ad.auctionType)];
    switch (sender.tag) {
        case kHZVideoViewTag:
            if (self.didStartVideo) {
                [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didFinishAudio];
                [HZAdsManager postNotificationName:kHeyzapDidFinishAudio infoProvider:self.ad];
            }
            
            self.didStartVideo = NO;
            
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
        self.didStartVideo = YES;
        
        [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] willStartAudio];
        [HZAdsManager postNotificationName:kHeyzapWillStartAudio infoProvider:self.ad];
        
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
        if (self.didStartVideo) {
            [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didFinishAudio];
            [HZAdsManager postNotificationName:kHeyzapDidFinishAudio infoProvider:self.ad];
        }
    
        self.didStartVideo = NO;
        self.didFinishVideo = YES;
        [self switchToViewWithTag: kHZWebViewTag];
    }
}


- (void) onActionError: (UIView *) sender {
    [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kAdFailedToLoadValue withProvider:self.ad network:HeyzapAdapterFromHZAuctionType(self.ad.auctionType)];
    
    if (sender.tag == kHZVideoViewTag && self.didStartVideo) {
        [[[HZAdsManager sharedManager] delegateForAdUnit:self.ad.adUnit] didFinishAudio];
        [HZAdsManager postNotificationName:kHeyzapDidFinishAudio infoProvider:self.ad];
    }
    
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
