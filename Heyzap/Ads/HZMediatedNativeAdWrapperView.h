//
//  HZMediatedNativeAdWrapperView.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HZMediatedNativeAdWrapperViewDelegate <NSObject>

- (void)wrapperView:(UIView *)wrapperView didMoveToWindow:(nullable UIWindow *)window;
- (void)wrapperView:(UIView *)wrapperView wasTapped:(UIGestureRecognizer *)gestureRecognizer;

@end

@interface HZMediatedNativeAdWrapperView : UIView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<HZMediatedNativeAdWrapperViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END