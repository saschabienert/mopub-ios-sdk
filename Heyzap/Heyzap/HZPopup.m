//
//  HZPopup.m
//  Heyzap
//
//  Created by Simon Maynard on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HZPopup.h"
#import "HeyzapSDKPrivate.h"
#import "HZAnalytics.h"
#import "HZUtils.h"

#define TRANSITION_DURATION 0.3
#define TAG_CHECKIN_BUTTON 1
#define TAG_CLOSE_BUTTON 2

static HZPopup *staticPopup = nil;

@implementation HZPopup

@synthesize backgroundView = _backgroundView;
@synthesize logoImage = _logoImage;
@synthesize label = _label;
@synthesize button = _button;
@synthesize stripedView=_stripedView;

static int yPositionOffset = 0;

#pragma  mark - Static Methods

+ (void)displayPopupWithMessage:(NSString *)message {
    [HZPopup displayPopupWithMessage: message andTimeout: 4.0];
}

+ (void) displayPopupWithMessage:(NSString *)message andTimeout: (NSTimeInterval) timeout {
    
    [HZPopup dismissPopup];
    
    staticPopup = [[HZPopup alloc] initWithMessage:message];
    [staticPopup showWithTimeout: timeout];
}

+ (void) dismissPopup {
    if (staticPopup != nil) {
        [staticPopup removeFromSuperview];
        staticPopup = nil;
    }
}


#pragma mark - Init

- (id)initWithMessage:(NSString *)message {
    self = [super initWithFrame: CGRectZero];
    if (self) {
        self.alpha = 1.0;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        // Init the background
        self.backgroundView = [[UIImageView alloc] initWithFrame: CGRectZero];
        self.backgroundView.image = [[UIImage imageNamed: @"Heyzap.bundle/bkg-popup.png"] stretchableImageWithLeftCapWidth: 5.0f topCapHeight: 0.0f];
        self.backgroundView.userInteractionEnabled = YES;
        self.backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        self.stripedView = [[UIView alloc] initWithFrame: CGRectZero];
        self.stripedView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"Heyzap.bundle/bkg-stripe.png"]];
        self.stripedView.opaque = NO;
        self.stripedView.alpha = 0.07;
        [self.backgroundView addSubview: self.stripedView];

        //Init the label
        self.label = [[UILabel alloc] initWithFrame: CGRectZero];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.lineBreakMode = UILineBreakModeWordWrap;
        self.label.numberOfLines = 0;
        self.label.font = [UIFont boldSystemFontOfSize:13.0];
        self.label.text = message;
        self.label.shadowOffset = CGSizeMake(0.0, -0.5);
        self.label.shadowColor = [UIColor colorWithRed: 76.0/255.0  green: 86.0/255.0 blue: 108.0/255.0 alpha: 1.0];
        self.label.lineBreakMode = UILineBreakModeTailTruncation;
        [self.backgroundView addSubview:self.label];
        
        // Init the button
        self.button = [[UIButton alloc] initWithFrame: CGRectZero];
        self.button.userInteractionEnabled = YES;
        [self.button addTarget: self action: @selector(buttonTapped:) forControlEvents: UIControlEventTouchUpInside];
        [self.button setImage: [UIImage imageNamed: @"Heyzap.bundle/btn-popup-checkin.png"] forState: UIControlStateNormal];
        self.button.tag = TAG_CHECKIN_BUTTON;
        
        [self.backgroundView addSubview: self.button];
        [self addSubview:self.backgroundView];
        
        //Init the logo
        self.logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Heyzap.bundle/icon-popup-logo.png"]];
        self.logoImage.backgroundColor = [UIColor clearColor];
        [self addSubview:self.logoImage];
        
        [self sizeToFitOrientation: YES];
    }
    return self;
}

#pragma mark - Actions

- (void) showWithTimeout: (NSTimeInterval) timeout {
    
    UIView *subview = [HZUtils windowOrNil];
    if (!subview) {
        return;
    }
    
    [HZAnalytics logAnalyticsEvent: @"popup_views"];
    [[HeyzapSDK sharedSDK] logDebugEvent: @"HZPopup: Popup showing"];
    
    [subview addSubview: self];
    
    self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:TRANSITION_DURATION/1.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
    self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
    [UIView commitAnimations];
    
    if (timeout != 0.0) {
        [self performSelector:@selector(dismiss) withObject: nil afterDelay: timeout];
    }
}

- (void) show {
    [[HeyzapSDK sharedSDK] logDebugEvent: @"HZPopup: Popup showing"];
    [self showWithTimeout: 0.0];
}

- (void) dismiss {
    [self moveBackAfterGameCenter];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.1];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(dismissAnimationStopped)];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

- (void) buttonTapped: (id) sender {
    [[HeyzapSDK sharedSDK] logDebugEvent: @"HZPopup: Popup clicked"];
    if ([sender tag] == TAG_CLOSE_BUTTON) {
        [self dismiss];
        return;
    }
    
    if ([HeyzapSDK canOpenHeyzap] == NO) {
        [HZAnalytics logAnalyticsEvent: @"popup_click"];
    } else {
        [HZAnalytics logAnalyticsEvent: @"popup_click_checkin"];
    }
    
    [[HeyzapSDK sharedSDK] rawCheckin:@""];
    [self dismiss];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self buttonTapped: nil];
}

+ (void) moveForGameCenter {
    //If we've already moved it then don't move it again - I fucking hate Game Center
    if (yPositionOffset == 50) {
        return;
    }
    yPositionOffset = 50;
    [staticPopup performSelector:@selector(moveBackAfterGameCenter) withObject:nil afterDelay:2.3];
    if (staticPopup != nil) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:TRANSITION_DURATION];
        if ( UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ) {
            staticPopup.center = CGPointMake(staticPopup.center.x + yPositionOffset, staticPopup.center.y);
        } else {
            staticPopup.center = CGPointMake(staticPopup.center.x, staticPopup.center.y + yPositionOffset);
        }
        [UIView commitAnimations];
    }
}

- (void) moveBackAfterGameCenter {
    yPositionOffset = 0;
    if (staticPopup != nil) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:TRANSITION_DURATION];
        [staticPopup sizeToFitOrientation:YES];
        [UIView commitAnimations];
    }
}

#pragma mark - Animation Events

- (void)bounce1AnimationStopped {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:TRANSITION_DURATION/2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
    self.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
    [UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:TRANSITION_DURATION/2];
    self.transform = [self transformForOrientation];
    [UIView commitAnimations];
}

- (void) dismissAnimationStopped {
    [self removeFromSuperview];
    staticPopup = nil;
    yPositionOffset = 0;
}

#pragma mark - Orientation

- (void) adjustForOrientation: (UIInterfaceOrientation) orientation {
    [self sizeToFitOrientation: YES];
}

- (void)sizeToFitOrientation:(BOOL)transform {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    // Presets
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    CGFloat height = 40.0;
    CGFloat buttonWidth = 69.0;
    CGFloat xOffset, width, stripeMargin;
    
    if (UIInterfaceOrientationIsLandscape(orientation) == YES) {
        self.bounds = CGRectMake(0.0, 0.0, 500.0, height + 15.0);
        stripeMargin = 3.0;
        width = 380.0;
        xOffset = 65.0;
    } else {
        self.bounds = CGRectMake(0.0, 0.0, 320.0, height + 15.0);
        stripeMargin = 3.0;
        width = 295.0;
        xOffset = 5.0;
    }
    
    // Set the sizes
    self.logoImage.frame = CGRectMake(xOffset, 5.0, 50.0, 50.0);
    self.backgroundView.frame = CGRectMake(xOffset + 12.0, 11.0, width, height);
    self.stripedView.frame = CGRectMake(stripeMargin, stripeMargin, width - (2 * stripeMargin), height - (2 * stripeMargin));
    self.button.frame = CGRectMake(self.backgroundView.frame.size.width - buttonWidth - 7.0, 7, buttonWidth, 26.0);
    self.label.frame = CGRectMake(40.0, 4.0, self.backgroundView.frame.size.width - 40.0 - buttonWidth - 10.0, 30.0);

    // Set the center of the view
    CGPoint center;
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            center = CGPointMake(frame.origin.x + self.bounds.size.height/2 + yPositionOffset, frame.origin.y + frame.size.height/2 + 10.0);     
            break;
        case UIInterfaceOrientationLandscapeRight:
            center = CGPointMake(frame.origin.x + frame.size.width - self.bounds.size.height/2 + yPositionOffset, frame.origin.y + frame.size.height/2 - 10.0);         
            break;
        case UIInterfaceOrientationPortrait:
            center = CGPointMake(frame.origin.x + frame.size.width/2, frame.origin.y + self.bounds.size.height/2 + yPositionOffset);           
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            center = CGPointMake(frame.origin.x + frame.size.width/2, frame.origin.y + frame.size.height - self.bounds.size.height/2 + yPositionOffset);
            break;
        default:
            break;
    }
    self.center = center;
}

@end
