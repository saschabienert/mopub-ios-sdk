//
//  HZUINavigationController.m
//  Heyzap
//
//  Created by Monroe Ekilah on 9/25/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//


#import "HZUINavigationController.h"

@implementation HZUINavigationController

- (instancetype) initWithRootViewController:(UIViewController *)rootViewController orientations:(UIInterfaceOrientationMask)orientations {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        _orientationMask = orientations;
    }
    
    return self;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return self.orientationMask;
}


@end