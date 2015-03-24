//
//  HZAdVideoController.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdViewController.h"
#import "HZVideoAdModel.h"

@interface HZAdVideoViewController : HZAdViewController<UIGestureRecognizerDelegate>

@property (nonatomic) HZVideoAdModel *ad;

- (void) show;
- (void) showWithOptions:(HZShowOptions *)options;
- (void) hide;

@end
