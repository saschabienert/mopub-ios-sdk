//
//  HZVideoControlView.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HZVideoControlView : UIView

@property (nonatomic) UILabel *timerTextLabel;
@property (nonatomic) UIButton *skipButton;
@property (nonatomic) UIButton *hideButton;

- (void) updateTimeRemaining: (int) timeRemaining;
- (void) updateSkipRemaining: (int) skipRemaining;

@end
