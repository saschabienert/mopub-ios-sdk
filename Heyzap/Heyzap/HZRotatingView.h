//
//  HZRotatingView.h
//  Heyzap
//
//  Created by Daniel Rhodes on 9/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HZRotatingViewProtocol <NSObject>
@optional
- (void)adjustForOrientation:(UIInterfaceOrientation)orientation;
@end

@interface HZRotatingView : UIView <HZRotatingViewProtocol>

- (void) addChangeObservers;
- (void) removeChangeObservers;
- (CGAffineTransform) transformForOrientation;
- (void) applicationDidRotate: (NSNotification *) notification;

@end
