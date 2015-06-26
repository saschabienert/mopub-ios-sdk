//
//  HZWebViewActivityIndicator.m
//  Heyzap
//
//  Created by Karim Piyarali on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZWebViewActivityIndicator.h"
#import "HZActivityIndicatorView.h"

@interface HZWebViewActivityIndicator()

@property (nonatomic) UILabel *labelView;
@property (nonatomic) UIView *activityIndicatorBackground;

- (HZActivityIndicatorView *) createActivityIndicatorView;
- (UIView *) createBackgroundView;
- (UILabel *) createLabelView;

@end

@implementation HZWebViewActivityIndicator

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
        
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                UIViewAutoresizingFlexibleBottomMargin |
                                UIViewAutoresizingFlexibleLeftMargin |
                                UIViewAutoresizingFlexibleRightMargin;
        
        UIView *parent = self;
        
        if (withBackgroundBox) {
            _activityIndicatorBackground = [self createBackgroundView];
            [parent addSubview:_activityIndicatorBackground];
            parent = _activityIndicatorBackground;
        }
        
        _activityIndicatorView = [self createActivityIndicatorView];
        [parent addSubview:_activityIndicatorView];
        
        _labelView = [self createLabelView];
        [parent insertSubview:_labelView belowSubview:_activityIndicatorView];
        
        // Other properties
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.hidden = YES;
    }
    
    return self;
}

#pragma mark - Init Helpers

- (HZActivityIndicatorView *)createActivityIndicatorView {
    HZActivityIndicatorView *activityIndicatorView = [[HZActivityIndicatorView alloc] initWithFrame:CGRectZero];
    
    activityIndicatorView.roundedCoreners = UIRectCornerAllCorners;
    activityIndicatorView.cornerRadii = CGSizeMake(3, 3);
    activityIndicatorView.stepDuration = 0.1;
    activityIndicatorView.color = [UIColor whiteColor];
    activityIndicatorView.direction = HZActivityIndicatorDirectionClockwise;
    activityIndicatorView.hidesWhenStopped = YES;
    activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                                UIViewAutoresizingFlexibleBottomMargin |
                                                UIViewAutoresizingFlexibleLeftMargin |
                                                UIViewAutoresizingFlexibleRightMargin;
    
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

- (UIView *)createBackgroundView {
    UIView *activityIndicatorBackground = [[UIView alloc] initWithFrame:CGRectZero];
    activityIndicatorBackground.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    activityIndicatorBackground.layer.cornerRadius = 7;
    activityIndicatorBackground.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                                    UIViewAutoresizingFlexibleBottomMargin |
                                                    UIViewAutoresizingFlexibleLeftMargin |
                                                    UIViewAutoresizingFlexibleRightMargin;
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

#pragma mark - Animate

- (void)startAnimating {
    [self.activityIndicatorView startAnimating];
    self.hidden = NO;
}

- (void)stopAnimating {
    self.hidden = YES;
    [self.activityIndicatorView stopAnimating];
}

#pragma mark - Superclass Overrides

#define kHZActivityIndicatorBackgroundWidthPadding 20.0f
#define kHZActivityIndicatorBackgroundHeightPadding 20.0f
#define kHZActivityIndicatorBottomPadding 10.0f

// Override
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.frame = CGRectMake(0, 0, CGRectGetWidth(self.superview.bounds), CGRectGetHeight(self.superview.bounds));
    
    [self.labelView sizeToFit];
    
    if (self.activityIndicatorBackground) {
        CGFloat activityIndicatorBackgroundWidth = MAX(self.labelView.frame.size.width, self.activityIndicatorView.frame.size.width) + kHZActivityIndicatorBackgroundWidthPadding;
        
        CGFloat activityIndicatorBackgroundHeight = self.activityIndicatorView.frame.size.height + self.labelView.frame.size.height + kHZActivityIndicatorBackgroundHeightPadding;
        
        self.activityIndicatorBackground.frame = CGRectMake(0,0, activityIndicatorBackgroundWidth, activityIndicatorBackgroundHeight);
        
        self.activityIndicatorBackground.center = self.center;
        
    } else {
        self.activityIndicatorView.center = self.center;
    }
    
    // Center label relative to parent and add bottom padding
    self.labelView.center = CGPointMake(self.activityIndicatorView.center.x,
                                        self.activityIndicatorView.center.y + self.activityIndicatorView.frame.size.height/2 + 5);
    
    if (self.labelView.text.length != 0) {
        // center activity indicator relative to parent and shift up for label
        self.activityIndicatorView.center = CGPointMake(self.activityIndicatorView.center.x,
                                                        self.activityIndicatorView.center.y - kHZActivityIndicatorBottomPadding);
    }
    
}

# pragma mark - Setters/Getters

- (void)setLabelText:(NSString *)labelText {
    _labelText = labelText;
    self.labelView.text = _labelText;
}

@end