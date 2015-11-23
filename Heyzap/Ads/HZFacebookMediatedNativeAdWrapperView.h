//
//  HZFacebookMediatedNativeAdWrapperView.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediatedNativeAdWrapperView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HZFacebookMediatedNativeAdWrapperViewDelegate <HZMediatedNativeAdWrapperViewDelegate>

- (id)underlyingNativeAd;
- (BOOL)shouldShowAdChoicesView;
- (UIRectCorner)adChoicesViewCorner;

@end

@interface HZFacebookMediatedNativeAdWrapperView : HZMediatedNativeAdWrapperView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<HZFacebookMediatedNativeAdWrapperViewDelegate>)delegate;

NS_ASSUME_NONNULL_END

@end
