//
//  HZLabeledActivityIndicator.m
//  Heyzap
//
//  Created by Karim Piyarali on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZLabeledActivityIndicator.h"
#import "HZHZActivityIndicatorView.h"

@interface HZLabeledActivityIndicator()

@property (nonatomic) UILabel *labelView;
@property (nonatomic) UIView *backgroundBox;
@property (nonatomic) BOOL superviewInteractionWasEnabled;

- (HZHZActivityIndicatorView *) createActivityIndicatorView;
- (UIView *) createBackgroundBox;
- (UILabel *) createLabelView;

@end

@implementation HZLabeledActivityIndicator

#pragma mark - Constants

#define kHZbackgroundBoxWidthPadding 20.0f
#define kHZbackgroundBoxHeightPadding 20.0f
#define kHZActivityLabelAndActivityIndicatorPadding 5.0f // space between label and spinner

UIViewAutoresizing const kHZActivityIndicatorDefaultAutoResizingMask = UIViewAutoresizingFlexibleTopMargin |
                                                                        UIViewAutoresizingFlexibleBottomMargin |
                                                                        UIViewAutoresizingFlexibleLeftMargin |
                                                                        UIViewAutoresizingFlexibleRightMargin;

#pragma mark - Init

- (instancetype)init {
    return [self initWithFrame:CGRectZero withBackgroundBox:NO];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame withBackgroundBox:NO];
}

- (instancetype) initWithFrame:(CGRect)frame withBackgroundBox:(BOOL)withBackgroundBox {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.autoresizingMask = kHZActivityIndicatorDefaultAutoResizingMask;
        
        self.opaque = NO;
        self.hidden = YES;
        
        // Add Subviews
        UIView *parent = self;
        
        if (withBackgroundBox) {
            _backgroundBox = [self createBackgroundBox];
            [parent addSubview:_backgroundBox];
            parent = _backgroundBox;
        }
        
        _activityIndicatorView = [self createActivityIndicatorView];
        [parent addSubview:_activityIndicatorView];
        
        _labelView = [self createLabelView];
        [parent addSubview:_labelView];
        
        _enableInteractionWithSuperview = NO;
    }
    
    return self;
}

#pragma mark - Init Helpers

- (HZHZActivityIndicatorView *)createActivityIndicatorView {
    HZHZActivityIndicatorView *activityIndicatorView = [[HZHZActivityIndicatorView alloc] initWithFrame:CGRectZero];
    
    activityIndicatorView.roundedCoreners = UIRectCornerAllCorners;
    activityIndicatorView.cornerRadii = CGSizeMake(3, 3);
    activityIndicatorView.stepDuration = 0.1;
    activityIndicatorView.color = [UIColor whiteColor];
    activityIndicatorView.direction = HZHZActivityIndicatorDirectionClockwise;
    activityIndicatorView.hidesWhenStopped = YES;
    activityIndicatorView.autoresizingMask = kHZActivityIndicatorDefaultAutoResizingMask;
    
    // device specific
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityIndicatorView.steps = 14;
        activityIndicatorView.finSize = CGSizeMake(5, 25);
        activityIndicatorView.indicatorRadius = 15;
        
    } else {
        activityIndicatorView.steps = 12;
        activityIndicatorView.finSize = CGSizeMake(3, 15);
        activityIndicatorView.indicatorRadius = 10;
    }
    
    return activityIndicatorView;
}

- (UIView *)createBackgroundBox {
    UIView *activityIndicatorBackground = [[UIView alloc] initWithFrame:CGRectZero];
    activityIndicatorBackground.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    activityIndicatorBackground.layer.cornerRadius = 7;
    activityIndicatorBackground.autoresizingMask = kHZActivityIndicatorDefaultAutoResizingMask;
    return activityIndicatorBackground;
}

- (UILabel *)createLabelView {
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectZero];
    labelView.opaque = NO;
    labelView.backgroundColor = [UIColor clearColor];
    labelView.textColor = [UIColor whiteColor];
    
    // device specific
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        labelView.font = [UIFont systemFontOfSize:18.0];
        
    } else {
        labelView.font = [UIFont systemFontOfSize:14.0];
    }
    
    return labelView;
}

#pragma mark - Superclass Overrides

// Override
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.frame = CGRectMake(0, 0, CGRectGetWidth(self.superview.bounds), CGRectGetHeight(self.superview.bounds));
    //self.center = self.superview.center; // this uses the frame center, not the bounds center. shouldn't be needed anyway since the center should be set when the frame is set...
    
    if (self.labelText.length) {
        [self.labelView sizeToFit];
    }
    
    CGSize activityIndicatorSize = self.activityIndicatorView.frame.size;
    CGSize labelSize = self.labelView.frame.size;
    
    if (self.backgroundBox) {
        CGFloat activityIndicatorBackgroundWidth = MAX(labelSize.width, activityIndicatorSize.width) + kHZbackgroundBoxWidthPadding;
        
        CGFloat activityIndicatorBackgroundHeight = activityIndicatorSize.height + labelSize.height + kHZbackgroundBoxHeightPadding;
        
        if (self.labelText.length) {
            activityIndicatorBackgroundHeight += kHZActivityLabelAndActivityIndicatorPadding;
        }
        
        self.backgroundBox.frame = CGRectMake(0, 0, activityIndicatorBackgroundWidth, activityIndicatorBackgroundHeight);
        self.activityIndicatorView.center = self.backgroundBox.center;
        self.backgroundBox.center = self.center;
        
    } else {
        self.activityIndicatorView.center = self.center;
    }
    
    if (self.labelText.length != 0) {
        // Re-position activity indicator to accomodate label
        self.activityIndicatorView.center = CGPointMake(self.activityIndicatorView.center.x,
                                                        self.activityIndicatorView.center.y - kHZActivityLabelAndActivityIndicatorPadding/2 - labelSize.height/2);
        // Position label
        self.labelView.center = CGPointMake(self.activityIndicatorView.center.x,
                                            self.activityIndicatorView.center.y + activityIndicatorSize.height/2 + labelSize.height/2 + kHZActivityLabelAndActivityIndicatorPadding);
    }
    
}

#pragma mark - Animate

- (void)startAnimating {
    if (!self.enableInteractionWithSuperview) {
        self.userInteractionEnabled = NO;
        self.superviewInteractionWasEnabled = self.superview.userInteractionEnabled;
        [self.superview setUserInteractionEnabled:NO];
    }
    
    [self.activityIndicatorView startAnimating];
    self.hidden = NO;
}

- (void)stopAnimating {
    self.hidden = YES;
    [self.activityIndicatorView stopAnimating];
    if (!self.enableInteractionWithSuperview) {
        self.userInteractionEnabled = YES;
        [self.superview setUserInteractionEnabled:self.superviewInteractionWasEnabled];
    }
}

# pragma mark - Setters/Getters

- (void)setLabelText:(NSString *)labelText {
    _labelText = labelText;
    self.labelView.text = _labelText;
}

- (void)setFadeBackground:(BOOL)fadeBackground {
    if (fadeBackground) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];

    } else {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:1.0];
    }
    
    _fadeBackground = fadeBackground;
}

@end