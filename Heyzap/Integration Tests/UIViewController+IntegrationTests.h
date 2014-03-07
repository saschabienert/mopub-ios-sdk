//
//  UIViewController+IntegrationTests.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (IntegrationTests)

/**
 *  Starting from a parent view controller, recursively searches downward for the most-child view controller.
 *  e.g. UINavigationController > SDCSegmentedVC > SDKTestAppViewController will find the SDKTestAppVC
 *
 *  @return The child view controller, or the receiver if no child view controller was found.
 */
- (UIViewController *)recursiveChildViewController;

@end
