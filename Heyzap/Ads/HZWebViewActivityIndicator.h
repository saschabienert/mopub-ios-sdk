//
//  HZWebViewActivityIndicator.h
//  Heyzap
//
//  Created by Karim Piyarali on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZActivityIndicatorView.h"

@interface HZWebViewActivityIndicator : UIView

@property (nonatomic) NSString *labelText;
@property (nonatomic) HZActivityIndicatorView *activityIndicatorView;

- (instancetype) initWithFrame:(CGRect)frame withBackgroundBox:(BOOL)withBackgroundBox;

- (void) startAnimating;
- (void) stopAnimating;

@end