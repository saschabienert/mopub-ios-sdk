//
//  HZVideoPopup.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/9/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZVideoView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HZVideoControlView.h"
#import "HZDevice.h"
#import "HZLog.h"

@interface HZVideoView()
@property (nonatomic) MPMoviePlayerController *player;
@property (nonatomic) UIInterfaceOrientation currOrientation;
@property (nonatomic) HZVideoControlView *controlView;
@property (nonatomic) BOOL didFinishVideo;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) BOOL durationAvailableFireImmediately;
@property (nonatomic) NSTimer *animationTimer;

#define kHZVideoViewAnimateInTime 0.0
#define kHZVideoViewAnimateInAlpha 1.0
#define kHZVideoViewAnimateOutTime 1.0
#define kHZVideoViewAnimateOutAlpha 0.0
#define kHZVideoViewAutoFadeOutTime 2

@end

@implementation HZVideoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = YES;
        [self registerForNotifications];
        
        self.backgroundColor = [UIColor clearColor];
        
        _showingAllVideoControls = true;
        
        _player = [[MPMoviePlayerController alloc] init];
        _player.controlStyle = MPMovieControlStyleNone;
        _player.view.frame = self.bounds;
        _player.scalingMode = MPMovieScalingModeAspectFit;
        
        _player.repeatMode = MPMovieRepeatModeNone;
        _player.shouldAutoplay = YES;
        
        _playbackTime = 0.0;
        _videoDuration = 0.0;
        
        _skipButtonTimeInterval = 0;
        
        [self addSubview: self.player.view];
        
        _controlView = [[HZVideoControlView alloc] initWithFrame: CGRectZero];
        UITapGestureRecognizer *clickTapGesture = [[UITapGestureRecognizer alloc]
                                                   initWithTarget: self action: @selector(onTap:)];
        clickTapGesture.delegate = self;
        _controlView.tag = 1;
        [_controlView addGestureRecognizer: clickTapGesture];
        [self addSubview: _controlView];

        _controlView.skipButton.tag = 2;
        [_controlView.skipButton addTarget: self action: @selector(onHide:) forControlEvents: UIControlEventTouchUpInside];
        _controlView.hideButton.tag = 3;
        [_controlView.hideButton addTarget: self action: @selector(onHide:) forControlEvents: UIControlEventTouchUpInside];
        
        _controlView.installButton.tag = 4;
        [_controlView.installButton addTarget: self action: @selector(onInstall:) forControlEvents: UIControlEventTouchUpInside];
    }
    return self;
}

- (void) registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerDurationAvailable:) name: MPMovieDurationAvailableNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerLoadStateDidChange:) name: MPMoviePlayerLoadStateDidChangeNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerNowPlayingMovieDidChange:) name: MPMoviePlayerNowPlayingMovieDidChangeNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerPlaybackDidFinish:) name: MPMoviePlayerPlaybackDidFinishNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerPlaybackStateDidChange:) name: MPMoviePlayerPlaybackStateDidChangeNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerScalingModeDidChange:) name: MPMoviePlayerScalingModeDidChangeNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationDidEnterBackground:) name: UIApplicationDidEnterBackgroundNotification object: nil];
    
    // This is only used in iOS 6...
    if (![HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
         [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerReadyForDisplayDidChange:) name: MPMoviePlayerReadyForDisplayDidChangeNotification object: nil];
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [self.player stop];
    [self.player.view removeFromSuperview];

    self.player = nil;
    self.controlView = nil;
    self.actionDelegate = nil;
    
    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (BOOL) setVideoURL: (NSURL *) url {
    if (!url) {
        return NO;
    }
    
    [self.player setContentURL: url];
    [self.player prepareToPlay];
    
    return YES;
}

- (void) pause {
    [self.player pause];
}

#pragma mark - Tap

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ! ([touch.view isKindOfClass:[UIControl class]]);
}

- (void) onTap: (id) sender {
    [self animateControls:!_showingAllVideoControls];
}

- (void) onHide: (id) sender {
    int remainingSkipButton = (self.skipButtonTimeInterval - self.player.currentPlaybackTime);
    if (remainingSkipButton < 1 || sender == self.controlView.hideButton) {
        if (self.player.currentPlaybackTime > self.playbackTime) {
            self.playbackTime = self.player.currentPlaybackTime;
        }
        
        [self.actionDelegate performSelector: @selector(onActionHide:) withObject: self];
    }
}

- (void) onInstall: (id) sender {
    if (self.actionDelegate != nil) {
        [self.actionDelegate performSelector: @selector(onActionClick:withURL:) withObject: self withObject: nil];
    }
}

#pragma mark - Animation
- (void) animateControls:(BOOL)animateIn {
    double alpha = animateIn ? kHZVideoViewAnimateInAlpha : kHZVideoViewAnimateOutAlpha;
    double duration = animateIn ? kHZVideoViewAnimateInTime : kHZVideoViewAnimateOutTime;
    
    [UIView animateWithDuration:duration
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations:^(void){
        [self.controlView.hideButton setAlpha:alpha];
        [self.controlView.skipButton setAlpha:alpha];
        [self.controlView.installButton setAlpha:alpha];
    }completion:^(BOOL finished){
        if(self.animationTimer){
            [self.animationTimer invalidate];
            self.animationTimer = nil;
        }
        
        // if we're showing the controls, set a timer to hide them
        if(animateIn) {
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval: kHZVideoViewAutoFadeOutTime target: self selector: @selector(animationTimerDidFire:) userInfo: nil repeats: NO];
        }
    }];
    
    self.showingAllVideoControls = animateIn;
}

- (void) animationTimerDidFire: (id) sender {
    // fade out video controls after this timer fires, if they're still showing.
    if(!self.showingAllVideoControls){
        return;
    }
    
    [self animateControls:NO];
}

- (void) removeFromSuperview {
    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [super removeFromSuperview];
}

#pragma mark - Timer

- (void) timerDidFire: (id) sender {
    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        // occasionally, the timer will fire earlier than the currentPlaybackTime can been determined.
        // in that case, set it to 0 (this happens at the start of the video playback)
        double currentPlaybackTime = self.player.currentPlaybackTime;
        if(isnan(currentPlaybackTime)){
            currentPlaybackTime = 0;
        }
        
        int remainingDuration = (int)(self.player.duration - currentPlaybackTime);
        [self.controlView updateTimeRemaining: remainingDuration];
        int skipRemaining = (self.skipButtonTimeInterval - currentPlaybackTime);
        if (skipRemaining > -1) {
            [self.controlView updateSkipRemaining: skipRemaining];
        } else {
            [self.controlView updateSkipRemaining: 0];
        }
    }
}

#pragma mark - View

- (void) layoutSubviews {
    self.player.view.frame = self.bounds;
    self.controlView.frame = self.bounds;
}

#pragma mark - On Screen Control Elements

- (void) setHideButton:(BOOL)value {
    _hideButton = value;
    self.controlView.hideButton.hidden = !value;
}

- (void) setSkipButton:(BOOL)value {
    _skipButton = value;
    self.controlView.skipButton.hidden = !value;
}

- (void) setInstallButton:(BOOL)value {
    _installButton = value;
    self.controlView.installButton.hidden = !value;
}

- (void) setTimerLabel:(BOOL)value {
    _timerLabel = value;
    self.controlView.timerTextLabel.hidden = !value;
}

#pragma mark - Video Notifications

- (void) mediaPlayerDurationAvailable: (id) notification {
    // show ad timer as soon as possible. if our timer is initialized, fire it right away to show ad timer.
    // if our timer isn't initialized yet, remember to fire the timer event immediately when it is.
    if(self.timer == nil) {
        _durationAvailableFireImmediately = true;
    } else {
        [self.timer fire];
    }
}
- (void) mediaPlayerNowPlayingMovieDidChange: (id) notification {}

- (void) mediaPlayerLoadStateDidChange: (id) notification {
    
    switch (self.player.loadState) {
        case MPMovieLoadStateUnknown:
            [HZLog debug: @"Media Playback: Load State Unknown"];
            if (self.actionDelegate != nil) {
                [self.actionDelegate performSelector: @selector(onActionError:) withObject: self];
            }
            break;
        case MPMovieLoadStatePlayable:
            if (self.actionDelegate != nil) {
                [self.actionDelegate performSelector: @selector(onActionReady:) withObject: self];
            }
            break;
        case MPMovieLoadStatePlaythroughOK:
            break;
        case MPMovieLoadStateStalled:
            break;
        default:
            break;
    }
}

- (void) mediaPlayerPlaybackDidFinish: (NSNotification *) notification {
    [self.player setFullscreen: NO animated: NO];
    
    if ((MPMovieFinishReason)[notification.userInfo objectForKey: MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] == MPMovieFinishReasonPlaybackError) {
        
        [HZLog debug: [NSString stringWithFormat: @"Reason: %@", notification.userInfo]];
        [HZLog debug: [NSString stringWithFormat: @"Error: %@", self.player.errorLog]];
        [HZLog debug: [NSString stringWithFormat: @"Log: %@", self.player.accessLog]];

        if (self.actionDelegate != nil) {
            [self.actionDelegate performSelector: @selector(onActionError:) withObject: self];
        }
    } else {
        if (self.actionDelegate != nil) {
            [self.actionDelegate performSelector: @selector(onActionCompleted:) withObject: self];
        }
    }
}

- (void) mediaPlayerPlaybackStateDidChange: (id) notification {
    // HACK! If the app goes into the background, this will restart the video when it comes back.
    if ([HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
        if (self.player.playbackState == MPMoviePlaybackStatePaused) {
            [self.player play];
        }
    }
    
    self.videoDuration = self.player.duration;

    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        if (self.timer == nil) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(timerDidFire:) userInfo: nil repeats: YES];
            if(_durationAvailableFireImmediately) {
                // only fire the timer immediately if we know the duration of the ad by now. otherwise, wait.
                [self.timer fire];
            }
            
            [self animateControls:YES];
        }
        
        self.videoDuration = self.player.duration;
        
        if (self.actionDelegate != nil) {
            [self.actionDelegate performSelector: @selector(onActionShow:) withObject: self];
        }
    }
}

- (void) mediaPlayerReadyForDisplayDidChange: (id) notification {
    // Push through aspect ratio changes
    self.controlView.frame = [self calculateNaturalFrameFromMovie: self.player withFrame: self.bounds];
    [self.controlView layoutSubviews];
    
    if ([self.superview.subviews lastObject] == self) [self.player play];
}

- (void) mediaPlayerScalingModeDidChange: (id) notification {}

- (CGRect) calculateNaturalFrameFromMovie: (MPMoviePlayerController *) controller withFrame: (CGRect) frame {
    CGSize naturalFrame = controller.naturalSize;

    // naturalSize can return 0 values in certain cases (e.g. part of the video is audio-only).
    // This prevents divide by zero https://app.asana.com/0/25787840548210/25833056427326
    if (naturalFrame.width == 0 || naturalFrame.height == 0) {
        return frame;
    }

    float originalAspectRatio = naturalFrame.width / naturalFrame.height;
	float maxAspectRatio = frame.size.width / frame.size.height;
    
    CGRect newRect = frame;
    
    if (originalAspectRatio > maxAspectRatio) {
        newRect.size.height = frame.size.width * (naturalFrame.height / naturalFrame.width);
        newRect.origin.y += (frame.size.height - frame.size.height)/2.0;
    } else {
        newRect.size.width = frame.size.height  * naturalFrame.width / naturalFrame.height;
        newRect.origin.x += (frame.size.width - newRect.size.width)/2.0;
    }
    
    return CGRectIntegral(newRect);
}

- (void) applicationDidEnterBackground: (id) notification {
    if ([HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
        [self.player pause];
    }
}

- (void) play {
    [self.player play];
}


@end
