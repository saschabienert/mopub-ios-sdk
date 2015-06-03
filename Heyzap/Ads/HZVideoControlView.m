//
//  HZVideoControlView.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZVideoControlView.h"
#import "HZDevice.h"

#define kHZVideoControlViewTimerSide 50.0
#define kHZVideoControlViewTimerPadding 10.0

#define kHZVideoControlViewInstallTop 5.0
#define kHZVideoControlViewInstallSide 5.0
#define kHZVideoControlViewInstallWidthPadding 30.0
#define kHZVideoControlViewInstallHeightPadding 0.0

@interface HZVideoControlView()
@property (nonatomic) NSString *skipFormatText;
@property (nonatomic) NSString *skipNowText;
@end

@implementation HZVideoControlView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _isTimeExpired = false;
        
        _timerTextLabel = [[UILabel alloc] initWithFrame: CGRectMake(0.0, 0.0, kHZVideoControlViewTimerSide, kHZVideoControlViewTimerSide)];
        _timerTextLabel.textColor = [UIColor whiteColor];
        _timerTextLabel.backgroundColor = [UIColor clearColor];
        _timerTextLabel.font = [UIFont boldSystemFontOfSize: 40.0];
        _timerTextLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
        _timerTextLabel.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _timerTextLabel.layer.shadowOpacity = 1.0f;
        _timerTextLabel.layer.shadowRadius = 0.0f;
        _timerTextLabel.layer.opacity = 0.8f;
        _timerTextLabel.hidden = YES;
        [self addSubview: _timerTextLabel];
        
        _skipButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _skipButton.frame = CGRectMake(0.0, 0.0, 80.0, 40.0);
        _skipButton.accessibilityLabel = @"skip";
        [_skipButton setTitle: @"" forState: UIControlStateNormal];
        [_skipButton.titleLabel setFont: [UIFont boldSystemFontOfSize: 20.0]];
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
        _hideButton.titleLabel.font = [UIFont boldSystemFontOfSize: 30.0];
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
        
        _installButton = [HZExtendedHitAreaButton buttonWithType: UIButtonTypeCustom];
        _installButton.frame = CGRectMake(0.0, 0.0, 80.0, 30.0);
        _installButton.accessibilityLabel = @"install";
        [_installButton.titleLabel setFont: [UIFont boldSystemFontOfSize: 24.0]];
        _installButton.titleLabel.textAlignment = UITextAlignmentCenter;
        _installButton.hidden = YES;
        _installButton.layer.opacity = 0.8f;
        _installButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        _installButton.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        _installButton.layer.shadowRadius = 0.0f;
        _installButton.layer.shadowOpacity = 1.0f;
        _installButton.layer.cornerRadius = 2;
        _installButton.layer.borderWidth = 1;
        _installButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        
        // make the hit area of the button larger than the button
        [_installButton setExtendedHitAreaMarginX:40];
        [_installButton setExtendedHitAreaMarginY:40];
        [self.installButton setTitle: @"Install Now" forState: UIControlStateNormal];
        [self addSubview: _installButton];
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    // Assumes control view has full screen
    
    self.timerTextLabel.frame = CGRectMake(kHZVideoControlViewTimerPadding,
                                           self.bounds.size.height - kHZVideoControlViewTimerSide,
                                           kHZVideoControlViewTimerSide + 40.0,
                                           kHZVideoControlViewTimerSide);
    
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

- (void) updateTimeRemaining:(int)timeRemaining {
    if (timeRemaining > 0) {
//        self.timerTextView.frame = CGRectMake(kHZVideoControlViewTimerPadding, self.bounds.size.height - kHZVideoControlViewTimerPadding - kHZVideoControlViewTimerSide, [, kHZVideoControlViewTimerSide);
        
        [[self timerTextLabel] setText: [NSString stringWithFormat: @"%i", timeRemaining]];
    } else {
        self.timerTextLabel.hidden = YES;
        _isTimeExpired = true;
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
