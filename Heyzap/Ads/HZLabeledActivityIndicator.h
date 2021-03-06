//
//  HZLabeledActivityIndicator.h
//  Heyzap
//
//  Created by Karim Piyarali on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZHZActivityIndicatorView.h"

@interface HZLabeledActivityIndicator : UIView

@property (nonatomic) BOOL fadeBackground;
@property (nonatomic) BOOL enableInteractionWithSuperview; // whether or not to allow users to interact with the superview while this indicator is showing
@property (nonatomic) NSString *labelText;
@property (nonatomic, readonly) HZHZActivityIndicatorView *activityIndicatorView;

- (instancetype) initWithFrame:(CGRect)frame withBackgroundBox:(BOOL)withBackgroundBox;

- (void) startAnimating;
- (void) stopAnimating;

@end