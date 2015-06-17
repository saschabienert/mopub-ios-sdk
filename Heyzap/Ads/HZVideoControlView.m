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

@interface HZVideoControlView()
@property (nonatomic) NSString *skipFormatText;
@property (nonatomic) NSString *skipNowText;
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
        _skipButton.accessibilityLabel = @"skip";
        [_skipButton setTitle: @"" forState: UIControlStateNormal];
        [_skipButton.titleLabel setFont: [UIFont boldSystemFontOfSize: 17.0]];
        _skipButton.titleLabel.textAlignment = UITextAlignmentCenter;
        _skipButton.hidden = YES;
        _skipButton.layer.opacity = 0.8f;
        _skipButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        _skipButton.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _skipButton.layer.shadowRadius = 0.0f;
        _skipButton.layer.shadowOpacity = 1.0f;
        [self addSubview: _skipButton];
        
        _hideButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _hideButton.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        [_hideButton setTitle: @"✕" forState: UIControlStateNormal];
        [_hideButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        _hideButton.backgroundColor = [UIColor clearColor];
        _hideButton.titleLabel.font = [UIFont boldSystemFontOfSize: 20.0];
        _hideButton.layer.opacity = 0.8f;
        _hideButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        _hideButton.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _hideButton.layer.shadowRadius = 0.0f;
        _hideButton.layer.shadowOpacity = 1.0f;
        _hideButton.hidden = YES;
        
        if ([HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
            self.skipFormatText = @"Skip in %is";
            self.skipNowText = @"Skip";
        } else {
            self.skipFormatText = @"Skip in %is ▶︎";
            self.skipNowText = @"Skip ▶︎";
        }
        
        [self addSubview: _hideButton];
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    // Assumes control view has full screen
    
    [self recalculateTimerFrame];
    
    CGSize textSize = [self.skipButton.titleLabel.text sizeWithFont: self.skipButton.titleLabel.font];
    self.skipButton.frame = CGRectMake(self.bounds.size.width - (textSize.width + 20.0),
                                       self.frame.origin.y,
                                       textSize.width + 30.0,
                                       self.skipButton.frame.size.height);
    
    self.hideButton.frame = CGRectMake(self.bounds.size.width - self.hideButton.frame.size.width,
                                       self.frame.origin.y,
                                       self.hideButton.frame.size.width,
                                       self.hideButton.frame.size.height);
    
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
    }
}

- (void) updateSkipRemaining: (int) skipRemaining {
    NSString *text;
    if (skipRemaining > 0) {
        text = [NSString stringWithFormat: self.skipFormatText, skipRemaining];
    } else {
        text = self.skipNowText;
    }
    
    [self.skipButton setTitle: text forState: UIControlStateNormal];
    
    CGSize textSize = [self.skipButton.currentTitle sizeWithFont: self.skipButton.titleLabel.font];
    self.skipButton.frame = CGRectMake(self.bounds.size.width - (textSize.width + 20.0), self.frame.origin.y, textSize.width + 30.0, self.skipButton.frame.size.height);
}

@end
