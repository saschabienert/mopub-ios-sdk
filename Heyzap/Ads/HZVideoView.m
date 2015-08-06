//
//  HZVideoView.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/9/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZVideoView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HZDevice.h"
#import "HZLog.h"

@interface HZVideoView()

@property (nonatomic) UIInterfaceOrientation currOrientation;
@property (nonatomic) BOOL didFinishVideo;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) BOOL durationAvailableFireImmediately;
@property (nonatomic) NSTimer *animationTimer;
@property (nonatomic) BOOL timerDidFireAlready;
@property (nonatomic) BOOL videoClickEnabled;
@property (nonatomic) BOOL skipButtonTimeIntervalValidated;
@property (nonatomic) BOOL didSendOnActionShowAlready;

#define kHZVideoViewAutoFadeOutControlsTimeSeconds 2 // number of seconds to leave controls on the screen before fading them out
#define kHZVideoViewMinumumSkippableSeconds 9 // minimum number of seconds a skip button should save a user in order for the button to be shown
#define kHZVideoViewOverrideSpammySkipTimeSeconds 5 // how many seconds to try and set the skip button to if the original time is determined to be spammy

@end

@implementation HZVideoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = YES;
        [self registerForNotifications];
        
        self.backgroundColor = [UIColor clearColor];
        
        _showingAllVideoControls = YES;
        _timerDidFireAlready = NO;
        _didSendOnActionShowAlready = NO;
        
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
        [_controlView addGestureRecognizer: clickTapGesture];
        [self addSubview: _controlView];

        [_controlView.skipButton addTarget: self action: @selector(onHide:) forControlEvents: UIControlEventTouchUpInside];
        [_controlView.hideButton addTarget: self action: @selector(onHide:) forControlEvents: UIControlEventTouchUpInside];
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
    
    // This is only used in iOS 6...
    if (![HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
         [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mediaPlayerReadyForDisplayDidChange:) name: MPMoviePlayerReadyForDisplayDidChangeNotification object: nil];
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [self.player stop];
    [self.player.view removeFromSuperview];

    _player = nil;
    _controlView = nil;
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
    if(self.videoClickEnabled){
        [self onInstall:nil];
    }else{
        [self animateControls: !self.showingAllVideoControls];
    }
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
    [self.actionDelegate performSelector: @selector(onActionClick:withURL:) withObject: self withObject: nil];
}

#pragma mark - Animation
- (void) animateControls:(BOOL)animateIn {
    double alpha = animateIn ? 1.0 : 0.0; // alpha value to animate the the controls in/out to
    double duration = animateIn ? 0.0 : 1.0; // how many seconds it takes to fade controls in/out
    
    // cancel any pending animations on the video controls since we're about to start animating them now.
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    
    [UIView animateWithDuration:duration
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations:^(void){
        [self.controlView.hideButton setAlpha:alpha];
        [self.controlView.skipButton setAlpha:alpha];
        [self.controlView.installButton setAlpha:alpha];
    }completion:^(BOOL finished){
        // if we're showing the controls, set a timer to hide them automatically later
        if(animateIn) {
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval: kHZVideoViewAutoFadeOutControlsTimeSeconds target: self selector: @selector(animationTimerDidFire:) userInfo: nil repeats: NO];
        }
    }];
    
    self.showingAllVideoControls = animateIn;
}

/**
 *  This method is called in order to automatically fade out video controls after a certain time period
 */
- (void) animationTimerDidFire: (id) sender {
    // fade out video controls after this timer fires, if they're still showing & we're using the new fading controls
    if(!self.showingAllVideoControls || self.videoClickEnabled){
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

- (void) timerDidFire: (NSTimer *) timer {
    self.timerDidFireAlready = YES;
    
    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        // occasionally, the timer will fire earlier than the currentPlaybackTime can been determined.
        // in that case, set it to 0 (this happens at the start of the video playback)
        double currentPlaybackTime = self.player.currentPlaybackTime;
        if(isnan(currentPlaybackTime)){
            currentPlaybackTime = 0;
        }
        
        if(self.player.duration > 0){
            // have a minimum amount of progress to report so the circular progress always shows up right away
            [self.controlView updateProgress:MAX((currentPlaybackTime/self.player.duration), 0.0001) delayUntilNextUpdate:timer.timeInterval];
        } else {
            HZDLog(@"HZVideoView player duration=%f bad for division.", self.player.duration);
        }
        
        int remainingDuration = (int)(self.player.duration - currentPlaybackTime);
        // +1 to time remaining reported to control view so that "0" is not displayed as the time remaining when there is between [0,1) seconds left
        [self.controlView updateTimeRemaining: remainingDuration + 1];
        if(remainingDuration > 0 && self.timerLabelEnabled) {
            self.controlView.circularProgressTimerLabel.hidden = NO;
        }
        
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

- (void) setHideButtonEnabled:(BOOL)value {
    _hideButtonEnabled = value;
    self.controlView.hideButton.hidden = !value;
}

- (void) setSkipButtonEnabled:(BOOL)value {
    _skipButtonEnabled = value;
    [self updateSkipButtonHiddenStatus];
}

- (void) updateSkipButtonHiddenStatus {
    BOOL shouldBeHidden = !(self.skipButtonEnabled && self.skipButtonTimeIntervalValidated);
    self.controlView.skipButton.hidden = shouldBeHidden;
}

- (void) setInstallButtonEnabled:(BOOL)value {
    _installButtonEnabled = value;
    self.controlView.installButton.hidden = !value;
}

- (void) setTimerLabelEnabled:(BOOL)value {
    _timerLabelEnabled = value;
    self.controlView.circularProgressTimerLabel.hidden = !value;
}

#pragma mark - Video Notifications

- (void) mediaPlayerDurationAvailable: (id) notification {
    if([self isSkipTimeSpammy:self.skipButtonTimeInterval]) {
        //duration and skip interval are almost the same, or duration is shorter than skip interval. don't be spammy and just default the skip time to something reasonable
        HZDLog(@"HZVideoView overriding a spammy skip button. Ad length: %f, skip interval: %f", self.player.duration, self.skipButtonTimeInterval);
        
        NSTimeInterval newSkipButtonTimeInterval = kHZVideoViewOverrideSpammySkipTimeSeconds;
        if([self isSkipTimeSpammy:newSkipButtonTimeInterval]){
            //really short video. just let them skip
            self.skipButtonTimeInterval = 0;
            HZDLog(@"HZVideoView video too short for a skip interval.");
        } else {
            self.skipButtonTimeInterval = newSkipButtonTimeInterval;
        }
    }
    
    self.skipButtonTimeIntervalValidated = YES;
    [self updateSkipButtonHiddenStatus];
    
    // show ad timer as soon as possible. if our timer is initialized, fire it right away to show ad timer.
    // if our timer isn't initialized yet, remember to fire the timer event immediately when it is.
    if(self.timer == nil) {
        _durationAvailableFireImmediately = true;
    } else if(!self.timerDidFireAlready) {
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
    self.videoDuration = self.player.duration;

    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        if (self.timer == nil) {
            // timer interval below should stay below 1 second to increase the visual accuracy of the circular progress animation
            self.timer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target: self selector: @selector(timerDidFire:) userInfo: nil repeats: YES];
            if(_durationAvailableFireImmediately) {
                // only fire the timer immediately if we know the duration of the ad by now. otherwise, wait.
                [self.timer fire];
            }
            
            // turn the video controls on when video starts (and schedule them to animate away later)
            [self animateControls:YES];
        }
        
        if (self.actionDelegate != nil && !self.didSendOnActionShowAlready) {
            [self.actionDelegate performSelector: @selector(onActionShow:) withObject: self];
            self.didSendOnActionShowAlready = YES;
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

- (void) play {
    [self.player play];
}

- (void) shouldUseClickableVideoConfiguration {
    self.videoClickEnabled = YES;
}

#pragma mark - Utilities
- (BOOL) isSkipTimeSpammy:(NSTimeInterval) skipTime {
    if(skipTime <= 0) {
        return NO;
    }
    
    if(ABS(self.player.duration - skipTime) <= kHZVideoViewMinumumSkippableSeconds || self.player.duration < skipTime) {
        return YES;
    }
    
    return NO;
}

@end
