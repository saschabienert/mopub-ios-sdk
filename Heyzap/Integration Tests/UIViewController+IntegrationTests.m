//
//  UIViewController+IntegrationTests.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "UIViewController+IntegrationTests.h"

@implementation UIViewController (IntegrationTests)

- (UIViewController *)recursiveChildViewController
{
    UIViewController *child = [self.childViewControllers firstObject];
    return child ? [child recursiveChildViewController] : self;
}

@end
