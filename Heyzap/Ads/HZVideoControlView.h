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
/**
 *  This button is tappable while the skip countdown is happening; this allows the skip button to intercept clicks.
 */
@property (nonatomic) UIButton *skipButton;
@property (nonatomic) UIButton *hideButton;

- (void) updateTimeRemaining: (int) timeRemaining;
- (void) updateSkipRemaining: (int) skipRemaining;

@end
