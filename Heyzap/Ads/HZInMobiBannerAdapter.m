//
//  HZInMobiBannerAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZInMobiBannerAdapter.h"
#import "HZIMBanner.h"
#import "HZIMBannerDelegate.h"

@interface HZInMobiBannerAdapter() <HZIMBannerDelegate>

@property (nonatomic) HZIMBanner *banner;
@property (nonatomic) BOOL bannerWasLoaded;

@end

@implementation HZInMobiBannerAdapter

- (instancetype)initWithAdPlacementID:(long long)placementID options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        
        const CGSize size = options.inMobiBannerSize;
        
        HZDLog(@"Initializing InMobi banner with Placement ID: %lld of size: %@",placementID, NSStringFromCGSize(size));
        _banner = [[HZIMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                        placementId:placementID
                                           delegate:self];
        [_banner load];
    }
    return self;
}


- (UIView *)mediatedBanner {
    return (UIView *)self.banner;
}

- (BOOL)isAvailable {
    return self.bannerWasLoaded;
}

#pragma mark - IMBannerDelegate

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"IMBannerDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)bannerWasAddedToView {
    // Override in subclass.
}

/**
 * Notifies the delegate that the banner has finished loading
 */
- (void)bannerDidFinishLoading:(HZIMBanner *)banner {
    self.bannerWasLoaded = YES;
    [self.bannerInteractionDelegate didReceiveAd];
}
/**
 * Notifies the delegate that the banner has failed to load with some error.
 */
- (void)banner:(HZIMBanner *)banner didFailToLoadWithError:(HZIMRequestStatus*)error {
    HZELog(@"InMobi failed to load banner with error: %@",error);
    NSError *castedError = (NSError *)error;
    [self.bannerInteractionDelegate didFailToReceiveAd:castedError];
}
/**
 * Notifies the delegate that the banner was interacted with.
 */
- (void)banner:(HZIMBanner *)banner didInteractWithParams:(NSDictionary*)params {
    // I've only seem the `params` dictionary be `nil` in testing. InMobi hasn't responded to my email asking for details about this.
    HZDLog(@"InMobi banner didInteractWithParams dictionary: %@",params);
    [self.bannerInteractionDelegate userDidClick];
}
/**
 * Notifies the delegate that the user would be taken out of the application context.
 */
- (void)userWillLeaveApplicationFromBanner:(HZIMBanner*)banner {
    [self.bannerInteractionDelegate willLeaveApplication];
}
/**
 * Notifies the delegate that the banner would be presenting a full screen content.
 */
- (void)bannerWillPresentScreen:(HZIMBanner*)banner {
    [self.bannerInteractionDelegate willPresentModalView];
}
/**
 * Notifies the delegate that the banner has finished presenting screen.
 */
- (void)bannerDidPresentScreen:(HZIMBanner*)banner {
    
}
/**
 * Notifies the delegate that the banner will start dismissing the presented screen.
 */
- (void)bannerWillDismissScreen:(HZIMBanner*)banner {
    
}
/**
 * Notifies the delegate that the banner has dismissed the presented screen.
 */
- (void)bannerDidDismissScreen:(HZIMBanner*)banner {
    [self.bannerInteractionDelegate didDismissModalView];
}
/**
 * Notifies the delegate that the user has completed the action to be incentivised with.
 */
- (void)banner:(HZIMBanner*)banner rewardActionCompletedWithRewards:(NSDictionary*)rewards {
    // I'm not sure if this is ever called. Currently I'm ignoring this method unless InMobi or a dev asks to be notified of it.
    HZDLog(@"InMobi banner rewardActionCompletedWithRewards dictionary: %@",rewards);
}

- (void)dealloc {
    // Explicitly niling the delegate is recommended by InMobi's docs.
    self.banner.delegate = nil;
}

@end
