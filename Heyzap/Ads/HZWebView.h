//
//  HZWebViewPopup.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZRotatingView.h"
#import "HZAdViewController.h"

@interface HZWebView : UIView<UIWebViewDelegate>

@property (nonatomic, weak) id<HZAdPopupActionDelegate> actionDelegate;
@property (nonatomic) BOOL isLoading;

- (void) setHTML: (NSString *) html;

@end
