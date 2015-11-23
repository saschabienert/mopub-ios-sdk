//
//  HZFBAdChoicesView.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZFBNativeAd;

@interface HZFBAdChoicesView : HZClassProxy

- (nonnull instancetype)initWithNativeAd:(nonnull HZFBNativeAd *)nativeAd;
- (void)updateFrameFromSuperview;
- (void)updateFrameFromSuperview:(UIRectCorner)corner;

@end
