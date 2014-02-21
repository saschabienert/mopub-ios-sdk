//
//  HZPopup.h
//  Heyzap
//
//  Created by Simon Maynard on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZRotatingView.h"
#import "Heyzap.h"

@interface HZPopup : HZRotatingView {
    UIImageView *_backgroundView;
    UILabel *_label;
    UIImageView *_logoImage;
    UIView *_stripedView;
    UIButton *_button;
}

@property (strong, nonatomic) UIImageView *backgroundView;
@property (strong, nonatomic) UIView *stripedView;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIImageView *logoImage;
@property (strong, nonatomic) UIButton *button;

+ (void) displayPopupWithMessage:(NSString *)message;
+ (void) displayPopupWithMessage:(NSString *)message andTimeout: (NSTimeInterval) interval;
+ (void) dismissPopup;
+ (void) moveForGameCenter;

- (id) initWithMessage:(NSString *)message;
- (void) showWithTimeout: (NSTimeInterval) timeout;
- (void) show;
- (void) dismiss;
- (void) sizeToFitOrientation:(BOOL)transform;
- (void) buttonTapped: (id) sender;
- (void) bounce1AnimationStopped;
- (void) bounce2AnimationStopped;
- (void) moveBackAfterGameCenter;
@end