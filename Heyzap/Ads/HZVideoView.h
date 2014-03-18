//
//  HZVideoView.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/9/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZRotatingView.h"
#import "HZAdViewController.h"

@interface HZVideoView : UIView<UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<HZAdPopupActionDelegate> actionDelegate;
@property (nonatomic, assign) BOOL hideButton;
@property (nonatomic, assign) NSTimeInterval skipButtonTimeInterval;
@property (nonatomic, assign) BOOL skipButton;
// Longest time video was played for.
@property (nonatomic, assign) NSTimeInterval playbackTime;
@property (nonatomic, assign) NSTimeInterval videoDuration;

- (BOOL) setVideoURL: (NSURL *) url;
- (void) pause;
- (void) play;

@end
