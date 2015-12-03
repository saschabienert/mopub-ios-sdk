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
#import "HZUtils.h"
#import "HZEnums.h"

#define kHZVideoViewTag 1
#define kHZWebViewTag 2

@interface HZAdVideoViewController ()<HZAdPopupActionDelegate>
@property (nonatomic) HZWebView *webView;
@property (nonatomic) HZVideoView *videoView;
@property (nonatomic) BOOL showOnReady;
@property (nonatomic) BOOL didFinishVideo;
@property (nonatomic) BOOL didStartVideo;
@end

@implementation HZAdVideoViewController

// The superclass implements the storage for this property;
// @dynamic is needed to subclass `ad` to `HZVideoAdModel`
@dynamic ad;

- (id) initWithAd:(HZVideoAdModel *)ad {
    self = [super initWithAd: ad];
    if (self) {
        _didFinishVideo = NO;
        
        _videoView = [[HZVideoView alloc] initWithFrame: CGRectZero];
        _videoView.tag = kHZVideoViewTag;
        
        if (ad.fileCached || ad.displayOptions.allowFallbacktoStreaming || ad.displayOptions.forceStreaming) {
            if (![_videoView setVideoURL: [self.ad URLForVideo]]) {
                return nil;
            }
        } else {
            [ad onInterstitialFallback];
            [self didImpression];
        }
        
        _videoView.actionDelegate = self;
        
        [_videoView setSkipButtonEnabled: self.ad.displayOptions.allowSkip];
        [_videoView setHideButtonEnabled: self.ad.displayOptions.allowHide];
        [_videoView setInstallButtonEnabled: self.ad.displayOptions.allowInstallButton];
        [_videoView setTimerLabelEnabled: self.ad.displayOptions.allowAdTimer];
        [_videoView setSkipButtonTimeInterval: [self.ad.displayOptions.lockoutTime doubleValue]/1000.0];
        [_videoView.controlView setInstallButtonText: self.ad.displayOptions.installButtonText];
        [_videoView.controlView setSkipNowText: self.ad.displayOptions.skipNowText];
        [_videoView.controlView setSkipLaterFormatText: self.ad.displayOptions.skipLaterFormattedText];
        
        _webView = [[HZWebView alloc] initWithFrame: CGRectZero];
        _webView.tag = kHZWebViewTag;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.actionDelegate = self;
        
        [_webView setHTML: self.ad.HTMLContent];
        
        _didStartVideo = NO;
        
    }
    return self;
}

- (void) dealloc {
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

- (void) closeAdView:(UIView *)adView {
    switch (adView.tag) {
        case kHZVideoViewTag:
            if (self.didStartVideo) {
                [HZAdsManager postNotificationName:kHeyzapDidFinishAudio infoProvider:self.ad];
            }
            
            self.didStartVideo = NO;
            
            if (self.ad.displayOptions.postRollInterstitial) {
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

- (void) hide {
    [self.ad onCompleteWithViewDuration: self.videoView.playbackTime andTotalDuration: self.videoView.videoDuration andFinished: self.didFinishVideo];
    
    if (self.ad.showableCreativeType == HZCreativeTypeIncentivized) {
        if (self.didFinishVideo) {
            [HZAdsManager postNotificationName:kHeyzapDidCompleteIncentivizedAd infoProvider:self.ad];
        } else {
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
    if (self.ad.fileCached || self.ad.displayOptions.allowFallbacktoStreaming || self.ad.displayOptions.forceStreaming) {
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

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Autorotation

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
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

#pragma mark - Callbacks

- (void) onActionHide: (UIView *) sender {
    [self closeAdView:sender];
}

- (void) onActionShow: (UIView *) sender {
    if (sender.tag == kHZVideoViewTag) {
        self.didStartVideo = YES;
        
        [HZAdsManager postNotificationName:kHeyzapWillStartAudio infoProvider:self.ad];
        
        [self didImpression];
    }
}

- (void) onActionReady: (UIView *) sender {
    
}

- (void) onActionClick: (UIView *) sender withURL: (NSURL *) url {
    if ([sender tag] == kHZVideoViewTag) {
        [self.videoView pause];
        [self didClickWithURL:url];
    }
    
    if ([sender tag] == kHZWebViewTag) {
        [self didClickWithURL:url];
    }
}

- (void) onActionCompleted: (UIView *) sender {
    if (sender.tag == kHZVideoViewTag) {
        self.didFinishVideo = YES;
        [self closeAdView:sender];
    }
}


- (void) onActionError: (UIView *) sender {
    if (sender.tag == kHZVideoViewTag && self.didStartVideo) {
        [HZAdsManager postNotificationName:kHeyzapDidFinishAudio infoProvider:self.ad];
    }
    
    if (sender.tag == kHZVideoViewTag && self.ad.displayOptions.postRollInterstitial) {
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


#pragma mark - Overridden from HZAdViewController

- (void) returnToAdFromClick {
    if ([self.view.subviews lastObject] == self.videoView) {
        [self.videoView play];
    }
}

@end
