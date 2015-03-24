//
//  HZBannerAdOptions_Private.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/13/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdOptions.h"
#import "HZFBAdView.h"
#import "HZGADBannerView.h"

@interface HZBannerAdOptions()

- (HZFBAdSize)internalFacebookAdSize;
+ (BOOL)facebookBannerSizesAvailable;

- (HZGADAdSize)internalAdMobSize;

@end