//
//  HZMediatedNativeAdWrapperView.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediatedNativeAdWrapperView.h"
#import "HZMediatedNativeAdViewRegisterer.h"


@interface HZMediatedNativeAdWrapperView()

@property (nonatomic, weak) id<HZMediatedNativeAdWrapperViewDelegate> delegate;

@end

@implementation HZMediatedNativeAdWrapperView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<HZMediatedNativeAdWrapperViewDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        _delegate = delegate;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wasTapped:)]];
    }
    return self;
}

- (void)didMoveToWindow {
    [self.delegate wrapperView:self didMoveToWindow:self.window];
}

- (void)wasTapped:(UIGestureRecognizer *)tapRecognizer {
    [self.delegate wrapperView:self wasTapped:tapRecognizer];
}

@end
