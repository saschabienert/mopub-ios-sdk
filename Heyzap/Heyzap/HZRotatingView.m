//
//  HZRotatingView.m
//  Heyzap
//
//  Created by Daniel Rhodes on 9/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HZRotatingView.h"

@interface HZRotatingView()

@property (nonatomic) UIInterfaceOrientation orientation;

@end

@implementation HZRotatingView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addChangeObservers];
        // Initialization code
    }
    return self;
}

- (void) dealloc {
    [self removeChangeObservers];
    
}

- (void) addChangeObservers {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationDidRotate:)
                                                 name: UIApplicationDidChangeStatusBarOrientationNotification object: nil];
}

- (void) removeChangeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver: self 
                                                    name: UIApplicationDidChangeStatusBarOrientationNotification
                                                  object: nil];
}

//Transforms the view according to the current orientation
- (CGAffineTransform)transformForOrientation {
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(-M_PI/2);
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation(M_PI/2);
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation(M_PI);
        default:
            return CGAffineTransformIdentity;
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    _orientation = [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)applicationDidRotate: (NSNotification *) notification {
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    if ( _orientation != [[UIApplication sharedApplication] statusBarOrientation] ) {
        if ( UIInterfaceOrientationIsPortrait(_orientation) && UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ) {
            duration *= 2;
        } else if ( UIInterfaceOrientationIsLandscape(_orientation) && UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ) {
            duration *= 2;
        }
    }
    _orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    [UIView animateWithDuration: duration animations:^{
        self.transform = [self transformForOrientation];
        if ([self respondsToSelector: @selector(adjustForOrientation:)]) {
            [self adjustForOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
        }
    }];
}

@end
