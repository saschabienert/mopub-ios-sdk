//
//  BaseTestAppViewController.h
//  Heyzap
//
//  Created by Maximilian Tagher on 2/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseTestAppViewController : UIViewController

@property (nonatomic, strong) UIScrollView *scrollView;


/** Updates the scrollView contentSize property to encapsulate all subviews. Subclasses should call this after adding views to the scrollview (typically, at the end of viewDidLoad). */
- (void)updateScrollViewContentSize;

@end
