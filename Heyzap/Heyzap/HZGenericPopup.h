//
//  HZGenericPopup.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZRotatingView.h"

@interface HZGenericPopup : HZRotatingView

@property (nonatomic, strong) UIView *contentView;

- (void) show;

- (void)sizeToFitOrientation:(BOOL)transform;

- (void)dismissAnimated:(BOOL)animated;
- (void) dismissAnimated:(BOOL)animated completion:(void(^)(void))completion;

@end
