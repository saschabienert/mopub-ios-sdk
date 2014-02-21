//
//  HZPopup.m
//  Heyzap
//
//  Created by Simon Maynard on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HZScorePopup.h"
#import "HeyzapSDKPrivate.h"
#import "HZAnalytics.h"
#import "HZLeaderboardRank.h"
#import <QuartzCore/QuartzCore.h>
#import "HZShadowGradientLayer.h"

#define TRANSITION_DURATION 0.3
#define TAG_CHECKIN_BUTTON 1
#define TAG_CLOSE_BUTTON 2

static HZScorePopup *staticPopup = nil;

@interface HZScorePopup()<UIAlertViewDelegate>

@end

@implementation HZScorePopup

static int yPositionOffset = -5.0;

#pragma  mark - Static Methods

+ (void)displayPopupWithRank:(HZLeaderboardRank *) rank {
    [HZScorePopup displayPopupWithRank: rank andTimeout: 4.0];
}

+ (void) displayPopupWithRank:(HZLeaderboardRank *)rank andTimeout: (NSTimeInterval) timeout {

    [HZScorePopup dismissPopup];

    staticPopup = [[HZScorePopup alloc] initWithRank: rank];
    [staticPopup showWithTimeout: timeout];
}

+ (void) dismissPopup {
    if (staticPopup != nil) {
        [staticPopup removeFromSuperview];
        staticPopup = nil;
    }
}

#pragma mark - Init

- (id) initWithRank:(HZLeaderboardRank *) rank {
    self = [super initWithFrame: CGRectZero];
    if (self) {
        self.rank = rank;
        
        self.alpha = 1.0;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        // Init the background
        self.backgroundView = [[UIImageView alloc] initWithFrame: CGRectZero];
        self.backgroundView.image = [[UIImage imageNamed: @"Heyzap.bundle/ui_overlay.png"] stretchableImageWithLeftCapWidth: 5.0f topCapHeight: 0.0f];
        self.backgroundView.userInteractionEnabled = YES;
        self.backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scorePopupTapped:)];
        [self.backgroundView addGestureRecognizer:tapRecognizer];
        
        self.logoImage = [[HZImageView alloc] initWithFrame: CGRectZero];
        self.logoImage.image = [UIImage imageNamed: @"Heyzap.bundle/icon-lb-hz-logo.png"];
        [self.backgroundView addSubview: self.logoImage];
        
        self.userImageShadow = [[UIView alloc] initWithFrame: CGRectZero];
        self.userImageShadow.backgroundColor = [UIColor blackColor];
        self.userImageShadow.layer.cornerRadius = 5.0;
        [self.backgroundView addSubview: self.userImageShadow];
        
        self.userImage = [[HZImageView alloc] initWithFrame: CGRectZero];
        if (!rank.loggedIn) {
            [self.userImage HZsetImageWithURL: nil placeholderImage: [UIImage imageNamed: @"Heyzap.bundle/default-user-photo.png"]];
        } else {
            [self.userImage HZsetImageWithURL: rank.userPicture placeholderImage: [UIImage imageNamed: @"Heyzap.bundle/default-user-photo.png"]];
        }
        
        [self.backgroundView addSubview: self.userImage];
        
        
        self.currentScoreLabel = [[UILabel alloc] initWithFrame: CGRectZero];
        self.currentScoreLabel.text = rank.currentScore.displayScore;
        self.currentScoreLabel.font = [UIFont boldSystemFontOfSize: 15.0];
        self.currentScoreLabel.backgroundColor = [UIColor clearColor];
        self.currentScoreLabel.shadowColor = [UIColor colorWithWhite: 0.0 alpha: 0.5];
        self.currentScoreLabel.shadowOffset = CGSizeMake(0.0, -0.5);
        self.currentScoreLabel.textColor = [UIColor colorWithRed: 178.0/255.0 green: 254.0/255.0 blue: 81.0/255.0 alpha:1.0];
        [self.backgroundView addSubview: self.currentScoreLabel];
        
        self.subCalloutLabel = [[UILabel alloc] initWithFrame: CGRectZero];
        if ([HeyzapSDK canOpenHeyzap] || self.rank.loggedIn) {
            self.subCalloutLabel.text = @"Personal Best:";
        } else {
            self.subCalloutLabel.text = @"Save your score with Heyzap.";
        }
        
        self.subCalloutLabel.backgroundColor = [UIColor clearColor];
        self.subCalloutLabel.shadowColor = [UIColor colorWithWhite: 0.0 alpha: 0.5];
        self.subCalloutLabel.shadowOffset = CGSizeMake(0.0, -0.5);
        self.subCalloutLabel.textColor = [UIColor whiteColor];
        self.subCalloutLabel.font = [UIFont boldSystemFontOfSize: 11.0];
        [self.backgroundView addSubview: self.subCalloutLabel];
          
        self.highScoreLabel = [[UILabel alloc] initWithFrame: CGRectZero];
        self.highScoreLabel.text = rank.bestScore.displayScore;
        self.highScoreLabel.font = [UIFont boldSystemFontOfSize: 11.0];
        self.highScoreLabel.backgroundColor = [UIColor clearColor];
        self.highScoreLabel.shadowColor = [UIColor colorWithWhite: 0.0 alpha: 0.5];
        self.highScoreLabel.shadowOffset = CGSizeMake(0.0, -0.5);
        self.highScoreLabel.textColor = [UIColor colorWithRed: 178.0/255.0 green: 254.0/255.0 blue: 81.0/255.0 alpha:1.0];
        self.highScoreLabel.hidden = !rank.loggedIn;
        [self.backgroundView addSubview: self.highScoreLabel];
        
        [self addSubview:self.backgroundView];
        
        [self sizeToFitOrientation: YES];
    }
    return self;
}

#pragma mark - Actions

- (void) showWithTimeout: (NSTimeInterval) timeout {
    
    [HZAnalytics logAnalyticsEvent: @"score_overlay_shown_top"];
    
    UIView *subview = [[UIApplication sharedApplication] keyWindow] ?
    [[UIApplication sharedApplication] keyWindow] : 
    [[[UIApplication sharedApplication] windows] objectAtIndex: 0];

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
    [[HeyzapSDK sharedSDK] logDebugEvent: @"HZScorePopup: Popup clicked"];
    [HZAnalytics logAnalyticsEvent: @"score_overlay_clicked_top"];
    
    if ([sender tag] == TAG_CLOSE_BUTTON) {
        [self dismiss];
        return;
    }
    
    if (![HeyzapSDK canOpenHeyzap]) {
        [HZAnalytics logAnalyticsEvent: @"score_in_game_overlay_install_clicked_top"];
    } else {
        [HZAnalytics logAnalyticsEvent: @"popup_click_checkin"];
    }
    
    [[HeyzapSDK sharedSDK] openLeaderboardLevel: self.rank.level.levelID];
    
    [self dismiss];
}

- (void)scorePopupTapped:(UITapGestureRecognizer *)tapRecognizer
{
    [self didAction:nil];
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
    
    CGSize currentScoreSize = [self.currentScoreLabel.text sizeWithFont: self.currentScoreLabel.font];
    
    self.currentScoreLabel.frame = CGRectMake(self.userImage.frame.origin.x + self.userImage.frame.size.width + 5.0, 3.0, currentScoreSize.width, currentScoreSize.height);
    
    CGSize widthCalloutSize = [self.subCalloutLabel.text sizeWithFont: self.subCalloutLabel.font];
    
    self.subCalloutLabel.frame = CGRectMake(self.currentScoreLabel.frame.origin.x, self.currentScoreLabel.frame.origin.y + self.currentScoreLabel.frame.size.height - 2.0, widthCalloutSize.width, widthCalloutSize.height);
    
    self.highScoreLabel.frame = CGRectMake(self.subCalloutLabel.frame.origin.x + self.subCalloutLabel.frame.size.width + 2.0, self.subCalloutLabel.frame.origin.y, widthCalloutSize.width, widthCalloutSize.height);

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
