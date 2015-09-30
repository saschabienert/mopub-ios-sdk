//
//  HZVideoView.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/9/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZRotatingView.h"
#import "HZAdViewController.h"
#import "HZVideoControlView.h"

@interface HZVideoView : UIView<UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<HZAdPopupActionDelegate> actionDelegate;

@property (nonatomic, readonly) HZVideoControlView *controlView;

@property (nonatomic) NSTimeInterval skipButtonTimeInterval;

@property (nonatomic) BOOL hideButtonEnabled;
@property (nonatomic) BOOL skipButtonEnabled;
@property (nonatomic) BOOL installButtonEnabled;
@property (nonatomic) BOOL timerLabelEnabled;
@property (nonatomic) BOOL showingAllVideoControls;

// Longest time video was played for.
@property (nonatomic) NSTimeInterval playbackTime;
@property (nonatomic) NSTimeInterval videoDuration;

@property (nonatomic, readonly) MPMoviePlayerController *player;

- (BOOL) setVideoURL: (NSURL *) url;
- (void) pause;
- (void) play;

/**
 *  Call this method to revert the video view back to using a clickable video with no install button and no fading controls.
 */
- (void) shouldUseClickableVideoConfiguration;

@end
