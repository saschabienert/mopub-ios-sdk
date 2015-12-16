//
//  HZFacebookMediatedNativeAdWrapperView.m
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZFacebookMediatedNativeAdWrapperView.h"
#import "HZFBAdChoicesView.h"

@interface HZFacebookMediatedNativeAdWrapperView()

@property (nonatomic) HZFBAdChoicesView *adChoicesView;
@property (nonatomic, weak) id<HZFacebookMediatedNativeAdWrapperViewDelegate> facebookDelegate;

@end

@implementation HZFacebookMediatedNativeAdWrapperView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<HZFacebookMediatedNativeAdWrapperViewDelegate>)delegate {
    self = [super initWithFrame:frame delegate:delegate];
    if (self) {
        _facebookDelegate = delegate;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self configureAdChoicesViewIfNecessary];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self configureAdChoicesViewIfNecessary];
}

- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
    [self configureAdChoicesViewIfNecessary];
}

- (void)configureAdChoicesViewIfNecessary {
    if ([self.facebookDelegate shouldShowAdChoicesView]) {
        if (!self.adChoicesView) {
            self.adChoicesView = [[HZFBAdChoicesView alloc] initWithNativeAd:[self.facebookDelegate underlyingNativeAd]];
        }
        // Add back view, just in case the developer removed it before.
        UIView *view = (UIView *)self.adChoicesView;
        if (!view.superview) {
            [self addSubview:view];
        }
        UIRectCorner corner = [self.facebookDelegate adChoicesViewCorner];
        [self.adChoicesView updateFrameFromSuperview:corner];
    } else {
        UIView *view = (UIView *)self.adChoicesView;
        [view removeFromSuperview];
    }
}

@end
