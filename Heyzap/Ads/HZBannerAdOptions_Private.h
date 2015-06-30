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

- (HZGADAdSize)internalAdMobSize;

+ (NSArray *)admobBannerSizes;
+ (NSArray *)facebookBannerSizes;
+ (NSArray *)heyzapExchangeBannerSizes;

NSValue *hzAdMobBannerSizeValue(HZAdMobBannerSize size);
NSValue *hzFacebookBannerSizeValue(HZFacebookBannerSize size);
NSValue *hzHeyzapExchangeBannerSizeValue(HZHeyzapExchangeBannerSize size);

HZAdMobBannerSize hzAdMobBannerSizeFromValue(NSValue *value);
HZFacebookBannerSize hzFacebookBannerSizeFromValue(NSValue *value);
HZHeyzapExchangeBannerSize hzHeyzapExchangeBannerSizeFromValue(NSValue *value);

NSString *hzFacebookBannerSizeDescription(HZFacebookBannerSize size);
NSString *hzAdMobBannerSizeDescription(HZAdMobBannerSize size);
NSString *hzHeyzapExchangeBannerSizeDescription(HZHeyzapExchangeBannerSize size);

/**
 *  Used by the test activity to override the ad network selection to 1 network.
 */
@property (nonatomic, strong) NSString *networkName;

- (BOOL)isFlexibleWidthForNetwork:(NSString *const)networkConstant;

@end