//
//  HZBannerAdOptions.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdOptions.h"
#import "HZMediationConstants.h"

@implementation HZBannerAdOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _facebookBannerSize = HZFacebookBannerSizeHeight50FlexibleWidth;
        _admobBannerSize = HZAdMobBannerSizeFlexibleWidthPortrait;
    }
    return self;
}


@end
