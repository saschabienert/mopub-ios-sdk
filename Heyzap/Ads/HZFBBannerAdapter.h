//
//  HZFBBannerAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdapter.h"
#import "HZFBAdView.h"

@interface HZFBBannerAdapter : HZBannerAdapter <HZFBAdViewDelegate>

- (instancetype)initWithHZFBAdView:(HZFBAdView *)adView;

@end
