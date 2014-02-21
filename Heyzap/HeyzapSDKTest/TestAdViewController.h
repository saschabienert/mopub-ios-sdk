//
//  TestAdViewController.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/7/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestAdViewController : UIViewController

@property (strong, nonatomic, readonly) IBOutlet UITextField *creativeIDTextField;

extern NSString * const kShowAdButtonAccessibilityLabel;
extern NSString * const kCreativeIDTextFieldAccessibilityLabel;

@end
