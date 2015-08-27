//
//  SDKTestAppViewControllerAdCallbackDelegate.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/27/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "SDKTestAppViewControllerAdCallbackDelegate.h"

#define METHOD_NAME NSStringFromSelector(_cmd)
#define MERGE_TWO_STRINGS(str1, str2) [NSString stringWithFormat:@"%@ %@", str1, str2]

@implementation SDKTestAppViewControllerAdCallbackDelegate
- (instancetype) initWthSDKTestAppViewController:(SDKTestAppViewController *)vc {
    self = [super init];
    if (self) {
        _vc = vc;
    }
    return self;
}
@end

@implementation SDKTestAppViewControllerHZAdsDelegate
- (void)didReceiveAdWithTag:(NSString *)tag {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:tag];
}
- (void)didShowAdWithTag:(NSString *)tag {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:tag];
}
- (void)didClickAdWithTag:(NSString *)tag {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:tag];
}
- (void)didHideAdWithTag:(NSString *)tag {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:tag];
}
- (void)didFailToReceiveAdWithTag:(NSString *)tag {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:tag];
}
- (void)didFailToShowAdWithTag:(NSString *)tag andError:(NSError *)error {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:[NSString stringWithFormat:@"tag: %@ error: %@",tag, error]];
}
- (void)willStartAudio {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME)];
}
- (void)didFinishAudio {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME)];
}
@end

@implementation SDKTestAppViewControllerHZIncentivizedAdDelegate
- (void)didCompleteAdWithTag:(NSString *)tag {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:tag];
}
- (void) didFailToCompleteAdWithTag:(NSString *)tag {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:tag];
}
@end

@implementation SDKTestAppViewControllerHZBannerAdDelegate
- (void)bannerDidReceiveAd:(HZBannerAd *)banner {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:banner.options.tag];
}
- (void)bannerDidFailToReceiveAd:(HZBannerAd *)banner error:(NSError *)error {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:banner.options.tag];
}
- (void)bannerWasClicked:(HZBannerAd *)banner {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:banner.options.tag];
}
- (void)bannerWillPresentModalView:(HZBannerAd *)banner {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:banner.options.tag];
}
- (void)bannerDidDismissModalView:(HZBannerAd *)banner {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:banner.options.tag];
}
- (void)bannerWillLeaveApplication:(HZBannerAd *)banner {
    [self.vc logCallback:MERGE_TWO_STRINGS(self.name, METHOD_NAME) withString:banner.options.tag];
}
@end
