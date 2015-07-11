//
//  SKMRAIDModalViewController.h
//  MRAID
//
//  Created by Jay Tucker on 9/20/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HZMRAIDModalViewController;
@class HZMRAIDOrientationProperties;

@protocol HZMRAIDModalViewControllerDelegate <NSObject>

- (void)mraidModalViewControllerDidRotate:(HZMRAIDModalViewController *)modalViewController;

@end

@interface HZMRAIDModalViewController : UIViewController

@property (nonatomic, unsafe_unretained) id<HZMRAIDModalViewControllerDelegate> delegate;

- (id)initWithOrientationProperties:(HZMRAIDOrientationProperties *)orientationProperties;
- (void)forceToOrientation:(HZMRAIDOrientationProperties *)orientationProperties;

@end
