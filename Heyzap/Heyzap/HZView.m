//
//  HZView.m
//  Heyzap
//
//  Created by Maximilian Tagher on 11/17/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZView.h"
#import "HZDevice.h"

@implementation HZView

+ (BOOL)isViewVisible:(UIView *)view {
    const BOOL basicVisibility = (view.isHidden == NO && view.alpha > 0);
    
    UIWindow *window = view.window;
    
    const CGPoint viewCenterInWindowCoordinates = ({
        CGPoint pt;
        if ([view respondsToSelector:@selector(convertPoint:toCoordinateSpace:)]) { // iOS 8+
            pt = [view convertPoint:view.center
             toCoordinateSpace:window.screen.fixedCoordinateSpace];
        } else {
            pt = [view convertPoint:view.center toView:window];
        }
        pt;
    });
    
    BOOL onScreen = CGRectContainsPoint(window.screen.bounds, viewCenterInWindowCoordinates);
    return basicVisibility && onScreen;
}

@end
