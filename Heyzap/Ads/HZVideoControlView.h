//
//  HZVideoControlView.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZExtendedHitAreaButton.h"
#import "HZKAProgressLabel.h"

@interface HZVideoControlView : UIView

extern NSString *const kHZSkipAccessibilityLabel;

@property (nonatomic) HZKAProgressLabel *circularProgressTimerLabel;
/**
 *  This button is tappable while the skip countdown is happening; this allows the skip button to intercept clicks.
 */
@property (nonatomic) UIButton *skipButton;
@property (nonatomic) UIButton *hideButton;
@property (nonatomic) HZExtendedHitAreaButton *installButton;
@property (nonatomic) NSString *skipLaterFormatText;
@property (nonatomic) NSString *skipNowText;
@property (nonatomic) NSString *installButtonText;

- (void) updateProgress: (CGFloat) progress delayUntilNextUpdate: (CGFloat) animationTime;
- (void) updateTimeRemaining: (int) timeRemaining;
- (void) updateSkipRemaining: (int) skipRemaining;

+ (void)setUseLargeHideButton:(BOOL)useLargeHideButton;

@end
