//
//  HZPlaySharedPopup.m
//  Heyzap
//
//  Created by Daniel Rhodes on 4/3/13.
//
//

#import "HZPlaySharedPopup.h"
#import "HeyzapSDK.h"
#import "HeyzapSDKPrivate.h"
#import "HZAnalytics.h"
#import "HZUser.h"
#import "HZUtils.h"
#import <QuartzCore/QuartzCore.h>
#import "HZShadowGradientLayer.h"

#define TRANSITION_DURATION 0.3
#define TAG_CHECKIN_BUTTON 1
#define TAG_CLOSE_BUTTON 2

static HZPlaySharedPopup *staticPopup = nil;

@interface HZPlaySharedPopup()<UIAlertViewDelegate>

@end

@implementation HZPlaySharedPopup

static int yPositionOffset = -5.0;

#pragma  mark - Static Methods

+ (void) displayPopupWithUser:(HZUser *)user {
    [HZPlaySharedPopup displayPopupWithUser: user andTimeout: 4.0];
}

+ (void) displayPopupWithUser:(HZUser *)user andTimeout:(NSTimeInterval)timeout {
    [HZPlaySharedPopup dismissPopup];
    
    staticPopup = [[HZPlaySharedPopup alloc] initWithUser: user];
    [staticPopup showWithTimeout: timeout];
}

+ (void) dismissPopup {
    if (staticPopup != nil) {
        [staticPopup removeFromSuperview];
        staticPopup = nil;
    }
}

#pragma mark - Init

- (id) initWithUser:(HZUser *) user {
    self = [super initWithFrame: CGRectZero];
    if (self) {
        self.user = user;
        self.alpha = 1.0;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        // Init the background
        self.backgroundView = [[UIImageView alloc] initWithFrame: CGRectZero];
        self.backgroundView.image = [[UIImage imageNamed: @"Heyzap.bundle/ui_overlay.png"] stretchableImageWithLeftCapWidth: 5.0 topCapHeight: 0.0f];
        self.backgroundView.userInteractionEnabled = YES;
        self.backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scorePopupTapped:)];
        [self.backgroundView addGestureRecognizer:tapRecognizer];
        
        self.logoImage = [[UIImageView alloc] initWithFrame: CGRectZero];
        self.logoImage.image = [UIImage imageNamed: @"Heyzap.bundle/icon-lb-hz-logo.png"];
        [self.backgroundView addSubview: self.logoImage];
        
        self.userImageShadow = [[UIView alloc] initWithFrame: CGRectZero];
        self.userImageShadow.backgroundColor = [UIColor blackColor];
        self.userImageShadow.layer.cornerRadius = 5.0;
        [self.backgroundView addSubview: self.userImageShadow];

        
        self.userImage = [[HZImageView alloc] initWithFrame: CGRectZero];
        self.userImage.layer.cornerRadius = 5.0;
        self.userImage.layer.masksToBounds = YES;

        NSURL *pictureURL = [NSURL URLWithString: self.user.picture];        
        [self.userImage HZsetImageWithURL: pictureURL placeholderImage: [UIImage imageNamed: @"Heyzap.bundle/default-user-photo.png"]];
        
        [self.backgroundView addSubview: self.userImage];
        
        self.calloutLabel = [[UILabel alloc] initWithFrame: CGRectZero];
        [self.calloutLabel setBackgroundColor: [UIColor clearColor]];
        self.calloutLabel.text = @"Play Shared!";
        self.calloutLabel.font = [UIFont boldSystemFontOfSize: 14.0];
        self.calloutLabel.textColor = [UIColor whiteColor];
        self.calloutLabel.shadowColor = [UIColor colorWithWhite: 0.0 alpha: 0.2];
        self.calloutLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        
        [self.backgroundView addSubview: self.calloutLabel];
        
        [self addSubview:self.backgroundView];
        
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
    
    [HZAnalytics logAnalyticsEvent: @"score_overlay_shown_top"];
    [subview addSubview: self];
    
    CGPoint temp = self.center;
    
    self.transform = [self transformForOrientation];
    switch([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationLandscapeLeft:
            self.center = CGPointMake(self.center.x - self.frame.size.height, self.center.y);
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.center = CGPointMake(self.center.x + self.frame.size.height, self.center.y);
            break;
        case UIInterfaceOrientationPortrait:
            self.center = CGPointMake(self.center.x, self.center.y - self.frame.size.height);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.center = CGPointMake(self.center.x, self.center.y + self.frame.size.height);
            break;
    }
    
    [UIView animateWithDuration: 0.3 animations:^{
        self.center = temp;
    } completion:^(BOOL finished) {
        [self sizeToFitOrientation: YES];
    }];
    
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
    
    [UIView animateWithDuration: 0.1 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void) didAction: (id) sender {
//    [[HeyzapSDK sharedSDK] logDebugEvent: @"HZScorePopup: Popup clicked"];
//    [HZAnalytics logAnalyticsEvent: @"score_overlay_clicked_top"];
    
    if ([sender tag] == TAG_CLOSE_BUTTON) {
        [self dismiss];
        return;
    }
    
//    if (![HeyzapSDK canOpenHeyzap]) {
//        [HZAnalytics logAnalyticsEvent: @"score_in_game_overlay_install_clicked_top"];
//    } else {
//        [HZAnalytics logAnalyticsEvent: @"popup_click_checkin"];
//    }
    
    [self dismiss];
}

- (void)scorePopupTapped:(UITapGestureRecognizer *)tapRecognizer
{
    [self didAction:nil];
}

+ (void) moveForGameCenter {
    //If we've already moved it then don't move it again - I fucking hate Game Center
    if (yPositionOffset == 20) {
        return;
    }
    yPositionOffset = 20;
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
    CGFloat xOffset, width;
    
    self.bounds = CGRectMake(0.0, 2 * yPositionOffset, frame.size.width, height + 5.0);
    width = 300.0;
    xOffset = (frame.size.width - width)/2;
    
    // Set the sizes
    //    self.logoImage.frame = CGRectMake(xOffset, 5.0, 50.0, 50.0);
    self.backgroundView.frame = CGRectMake(xOffset, 0.0, width, height);
    self.logoImage.frame = CGRectMake(width - self.logoImage.image.size.width - 5.0, 2.0, self.logoImage.image.size.width, self.logoImage.image.size.height);
    
    self.userImage.frame = CGRectMake(7.0, 3.5, height - 10.0, height - 10.0);
    self.userImage.layer.cornerRadius = 3.0;
    self.userImage.layer.masksToBounds = YES;
    self.userImage.hidden = NO;
    
    self.userImageShadow.frame = self.userImage.frame;
    self.userImageShadow.layer.shadowColor = [UIColor blackColor].CGColor;
    self.userImageShadow.layer.shadowOpacity = 0.25;
    self.userImageShadow.layer.shadowRadius = 3.0;
    self.userImageShadow.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    
	HZShadowGradientLayer *innerShadowlayer = [[HZShadowGradientLayer alloc] init];
	innerShadowlayer.colors = (@[ (id)[UIColor colorWithWhite:1 alpha:0.0].CGColor,
                               (id)[UIColor colorWithWhite:1 alpha:0.0].CGColor]);
    
	innerShadowlayer.frame = self.userImage.bounds;
	innerShadowlayer.cornerRadius = 3.0;
    
	innerShadowlayer.innerShadowOpacity = 0.0f;
	innerShadowlayer.innerShadowColor = [UIColor whiteColor].CGColor;
    
	innerShadowlayer.borderColor = [UIColor colorWithWhite: 1.0 alpha: 0.25].CGColor;
	innerShadowlayer.borderWidth = 0.5f;
    
    [self.userImage.layer addSublayer: innerShadowlayer];
    
//    self.userImageOverlay.frame = CGRectMake(self.logoImage.image.size.width + 10.0, 1.0, height - 1.0, height - 1.0);
    
    self.calloutLabel.frame = CGRectMake(self.userImage.frame.origin.x + self.userImage.frame.size.width + 5.0, -1.0, 200.0, self.backgroundView.frame.size.height);
    //[self.calloutLabel setBackgroundColor: [UIColor c]];
    
    // Set the center of the view
    CGPoint center;
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            center = CGPointMake(frame.origin.x + self.bounds.size.height/2 + (2 * yPositionOffset), frame.origin.y + frame.size.height/2 + 10.0);
            break;
        case UIInterfaceOrientationLandscapeRight:
            center = CGPointMake(frame.origin.x + frame.size.width - self.bounds.size.height/2 + (2 * yPositionOffset), frame.origin.y + frame.size.height/2 - 10.0);
            break;
        case UIInterfaceOrientationPortrait:
            center = CGPointMake(frame.origin.x + frame.size.width/2, frame.origin.y + self.bounds.size.height/2 + (2 * yPositionOffset));
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            center = CGPointMake(frame.origin.x + frame.size.width/2, frame.origin.y + frame.size.height - self.bounds.size.height/2 + (2 * yPositionOffset));
            break;
        default:
            break;
    }
    
    self.center = center;
}

@end
