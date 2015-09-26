//
//  HZUINavigationController.h
//  Heyzap
//
//  Created by Monroe Ekilah on 9/25/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UINavigationController.h>


/**
 *  A subclass of UINavigationController that overrides `supportedInterfaceOrientations:` to return it's property `orientationMask`.
 */
@interface HZUINavigationController : UINavigationController

@property (nonatomic) UIInterfaceOrientationMask orientationMask;

- (nullable instancetype) initWithRootViewController:(nonnull UIViewController *)rootViewController orientations:(UIInterfaceOrientationMask)orientations;


@end