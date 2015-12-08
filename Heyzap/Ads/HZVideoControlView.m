//
//  HZVideoControlView.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZVideoControlView.h"
#import "HZDevice.h"

#define kHZVideoControlViewTimerCircleXPadding 5.0 // brings timer circle away from side edge of screen
#define kHZVideoControlViewTimerCircleYPadding 5.0 // brings timer circle up from top/bottom edge of screen
#define kHZVideoControlViewTimerCircleTextPadding 13.0 // makes timer circle larger to accomodate text without overlap

#define kHZVideoControlViewInstallTop 5.0
#define kHZVideoControlViewInstallSide 5.0
#define kHZVideoControlViewInstallWidthPadding 30.0
#define kHZVideoControlViewInstallHeightPadding 0.0

NSString *const kHZSkipAccessibilityLabel = @"skip";

@interface HZVideoControlView()

@end

@implementation HZVideoControlView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _circularProgressTimerLabel = [[HZKAProgressLabel alloc] init];
        _circularProgressTimerLabel.fillColor = [UIColor clearColor]; // color inside the circular label
        _circularProgressTimerLabel.trackColor = [UIColor clearColor]; // color of the circular outline behind the progress
        _circularProgressTimerLabel.progressColor = [UIColor lightGrayColor]; // color of the countdown
        _circularProgressTimerLabel.trackWidth = 1.5;
        _circularProgressTimerLabel.progressWidth = 2.5;
        _circularProgressTimerLabel.roundedCornersWidth = 0;
        
        _circularProgressTimerLabel.textColor = [UIColor whiteColor];
        _circularProgressTimerLabel.backgroundColor = [UIColor clearColor];
        _circularProgressTimerLabel.font = [UIFont boldSystemFontOfSize: 14.0];
        _circularProgressTimerLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
        _circularProgressTimerLabel.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _circularProgressTimerLabel.layer.shadowOpacity = 1.0f;
        _circularProgressTimerLabel.layer.shadowRadius = 0.0f;
        _circularProgressTimerLabel.layer.opacity = 0.8f;
        _circularProgressTimerLabel.hidden = YES;
        _circularProgressTimerLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview: _circularProgressTimerLabel];
        
        _skipButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _skipButton.frame = CGRectMake(0.0, 0.0, 80.0, 40.0);
        _skipButton.accessibilityLabel = kHZSkipAccessibilityLabel;
        [_skipButton setTitle: @"" forState: UIControlStateNormal];
        [_skipButton.titleLabel setFont: [UIFont boldSystemFontOfSize: 17.0]];
        _skipButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _skipButton.hidden = YES;
        _skipButton.layer.opacity = 0.8f;
        _skipButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        _skipButton.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _skipButton.layer.shadowRadius = 0.0f;
        _skipButton.layer.shadowOpacity = 1.0f;
        [self addSubview: _skipButton];
        
        const CGFloat hideButtonSide = hzUseLargeHideButton ? 40.0 : 80.0;
        
        _hideButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _hideButton.accessibilityLabel = kHZSkipAccessibilityLabel;
        _hideButton.frame = CGRectMake(0.0, 0.0, hideButtonSide, hideButtonSide);
        [_hideButton setTitle: @"✕" forState: UIControlStateNormal];
        [_hideButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        _hideButton.backgroundColor = [UIColor clearColor];
        _hideButton.titleLabel.font = [UIFont boldSystemFontOfSize: (hzUseLargeHideButton ? 40 : 20)];
        _hideButton.layer.opacity = 0.8f;
        _hideButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        _hideButton.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _hideButton.layer.shadowRadius = 0.0f;
        _hideButton.layer.shadowOpacity = 1.0f;
        _hideButton.hidden = YES;
        
        [self addSubview: _hideButton];
        
        _installButton = [HZExtendedHitAreaButton buttonWithType: UIButtonTypeCustom];
        _installButton.frame = CGRectMake(0.0, 0.0, 80.0, 30.0);
        _installButton.accessibilityLabel = @"install";
        [_installButton.titleLabel setFont: [UIFont boldSystemFontOfSize: 17.0]];
        _installButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _installButton.hidden = YES;
        _installButton.layer.opacity = 0.8f;
        _installButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        _installButton.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _installButton.layer.shadowRadius = 0.0f;
        _installButton.layer.shadowOpacity = 1.0f;
        _installButton.layer.cornerRadius = 2;
        _installButton.layer.borderWidth = 1;
        _installButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        _installButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
        
        // make the hit area of the button larger than the button
        [_installButton setExtendedHitAreaMarginX:40];
        [_installButton setExtendedHitAreaMarginY:40];
        [self addSubview: _installButton];
        
        //defaults
        _skipNowText = @"Skip ▶︎";
        _skipLaterFormatText = @"Skip in %is ▶︎";
        _installButtonText = @"Install Now";
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    // Assumes control view has full screen
    
    [self recalculateTimerFrame];
    
    CGSize skipButtonTextSize = [self.skipButton.titleLabel.text sizeWithFont: self.skipButton.titleLabel.font];
    self.skipButton.frame = CGRectMake(self.bounds.size.width - (skipButtonTextSize.width + 20.0),
                                       self.frame.origin.y,
                                       skipButtonTextSize.width + 30.0,
                                       self.skipButton.frame.size.height);
    
    self.hideButton.frame = CGRectMake(self.bounds.size.width - self.hideButton.frame.size.width,
                                       self.frame.origin.y,
                                       self.hideButton.frame.size.width,
                                       self.hideButton.frame.size.height);
    
    CGSize installButtonTextSize = [self.installButton.titleLabel.text sizeWithFont: self.installButton.titleLabel.font];
    self.installButton.frame = CGRectMake(self.frame.origin.x + kHZVideoControlViewInstallSide,
                                           self.frame.origin.y + kHZVideoControlViewInstallTop,
                                           installButtonTextSize.width + kHZVideoControlViewInstallWidthPadding,
                                           self.installButton.frame.size.height + kHZVideoControlViewInstallHeightPadding);
    
}

/** Automatically adjusts the frame size of the circular timer to fit the timer text within */
- (void) recalculateTimerFrame {
    CGSize textFrame = [self.circularProgressTimerLabel.text sizeWithFont: self.circularProgressTimerLabel.font];
    CGFloat maxTextDimension = MAX(textFrame.height, textFrame.width);
    CGFloat circularProgressTimerSize = kHZVideoControlViewTimerCircleTextPadding + maxTextDimension;
    
    self.circularProgressTimerLabel.frame = CGRectMake(kHZVideoControlViewTimerCircleXPadding,self.bounds.size.height - circularProgressTimerSize - kHZVideoControlViewTimerCircleYPadding, circularProgressTimerSize, circularProgressTimerSize);
}

/** Takes a progress value [0,1] and uses it to set the */
- (void) updateProgress: (CGFloat) progress delayUntilNextUpdate: (CGFloat) animationTime{
    // set the "start degree" in order to make the countdown clockwise. Otherwise, use the "end degree"
    [self.circularProgressTimerLabel setStartDegree:(progress)*360.0f timing:HZTPPropertyAnimationTimingLinear duration:animationTime delay:0];
}

- (void) updateTimeRemaining:(int)timeRemaining {
    if (timeRemaining >= 0) {
        [[self circularProgressTimerLabel] setText: [NSString stringWithFormat: @"%i", timeRemaining]];
        [self recalculateTimerFrame];
    } else {
        self.circularProgressTimerLabel.hidden = YES;
    }
}

- (void) updateSkipRemaining: (int) skipRemaining {
    NSString *text;
    if (skipRemaining > 0) {
        text = [NSString stringWithFormat: self.skipLaterFormatText, skipRemaining];
    } else {
        text = self.skipNowText;
    }
    
    [self.skipButton setTitle: text forState: UIControlStateNormal];
    
    CGSize textSize = [self.skipButton.currentTitle sizeWithFont: self.skipButton.titleLabel.font];
    self.skipButton.frame = CGRectMake(self.bounds.size.width - (textSize.width + 20.0), self.frame.origin.y, textSize.width + 30.0, self.skipButton.frame.size.height);
}

- (void) setSkipNowText:(NSString *)skipNowText {
    _skipNowText = [skipNowText stringByAppendingString: @" ▶︎"];
}

- (void) setSkipLaterFormatText:(NSString *)skipLaterFormatText {
    _skipLaterFormatText = [skipLaterFormatText stringByAppendingString: @" ▶︎"];
}

- (void) setInstallButtonText:(NSString *)installButtonText {
    _installButtonText = installButtonText;
    [self.installButton setTitle: _installButtonText forState: UIControlStateNormal];
}

static BOOL hzUseLargeHideButton = NO;

+ (void)setUseLargeHideButton:(BOOL)useLargeHideButton {
    hzUseLargeHideButton = useLargeHideButton;
}

@end
